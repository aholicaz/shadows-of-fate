"""Prepare the user-authorized chroma-key animation artwork for Godot.

Uses Pillow + numpy. Source artwork and prompts live in output/war_wraith.
Keeps each animation at a constant scale, preserving attack/death motion.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'output/war_wraith'
DEST = ROOT / 'Sprites/monsters/generated/chapter3/war_wraith_animations'
NAMES = ('idle', 'walk', 'attack', 'hit', 'die')
SIZE = 512
ANCHOR = (240, 448)


def key_magenta(image):
    rgb = np.asarray(image.convert('RGB'), dtype=np.float32)
    excess = np.minimum(rgb[:, :, 0], rgb[:, :, 2]) - rgb[:, :, 1]
    # Generated key color is slightly compressed/noisy, not mathematically FF00FF.
    alpha = np.clip((160.0 - excess) / 125.0, 0, 1)
    alpha[alpha < .035] = 0
    # Undo magenta contamination in partially covered edge pixels.
    bg = np.array([255., 0., 255.])
    clean = (rgb - (1 - alpha[:, :, None]) * bg) / np.maximum(alpha[:, :, None], .001)
    clean = np.clip(clean, 0, 255).astype(np.uint8)
    spill = (clean[:, :, 0].astype(float) > clean[:, :, 1] + 35.0) & (clean[:, :, 2].astype(float) > clean[:, :, 1] + 35.0)
    clean[:, :, 0][spill] = np.minimum(clean[:, :, 0][spill], clean[:, :, 1][spill].astype(float) + 20).astype(np.uint8)
    clean[alpha == 0] = 0
    return np.dstack((clean, np.rint(alpha * 255).astype(np.uint8)))


def components(mask):
    """Eight-connected scanline components; avoids slicing through sword tips."""
    parents = [0]
    runs = []
    previous = []

    def root(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i

    for y, row in enumerate(mask):
        edges = np.diff(np.r_[False, row, False].astype(np.int8))
        starts, ends = np.flatnonzero(edges == 1), np.flatnonzero(edges == -1)
        current = []
        p = 0
        for x0, x1 in zip(starts.tolist(), ends.tolist()):
            while p < len(previous) and previous[p][1] < x0:
                p += 1
            touching = []
            q = p
            while q < len(previous) and previous[q][0] <= x1:
                touching.append(root(previous[q][2]))
                q += 1
            if touching:
                label = min(touching)
                for other in touching:
                    parents[root(other)] = label
            else:
                label = len(parents)
                parents.append(label)
            current.append((x0, x1, label))
            runs.append((y, x0, x1, label))
        previous = current
    labels = np.zeros(mask.shape, dtype=np.int32)
    bounds = {}
    counts = {}
    for y, x0, x1, label in runs:
        r = root(label)
        labels[y, x0:x1] = r
        counts[r] = counts.get(r, 0) + x1 - x0
        b = bounds.setdefault(r, [x0, y, x1, y + 1])
        b[0], b[1], b[2], b[3] = min(b[0], x0), min(b[1], y), max(b[2], x1), max(b[3], y + 1)
    return labels, bounds, counts


def extract_poses(rgba):
    labels, bounds, counts = components(rgba[:, :, 3] >= 10)
    main = sorted(counts, key=counts.get, reverse=True)[:8]
    assert len(main) == 8 and min(counts[k] for k in main) > 5000, 'Need eight complete characters'
    main.sort(key=lambda k: (int((bounds[k][1] + bounds[k][3]) / 2 >= rgba.shape[0] / 2), bounds[k][0]))
    assert sum((bounds[k][1] + bounds[k][3]) / 2 < rgba.shape[0] / 2 for k in main) == 4
    owners = {k: i for i, k in enumerate(main)}
    # Attach detached flame particles to the closest character bounding box.
    for k, b in bounds.items():
        if k in owners or counts[k] < 3:
            continue
        cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
        scores = []
        for j in main:
            a = bounds[j]
            dx = max(a[0] - cx, 0, cx - a[2])
            dy = max(a[1] - cy, 0, cy - a[3])
            tie = ((cx - (a[0]+a[2])/2)**2 + (cy - (a[1]+a[3])/2)**2) * .005
            scores.append(dx * dx + dy * dy + tie)
        nearest = int(np.argmin(scores))
        if scores[nearest] < 3000:
            owners[k] = nearest
    lookup = np.full(int(labels.max()) + 1, -1, dtype=np.int16)
    for k, owner in owners.items():
        lookup[k] = owner
    owner_map = lookup[labels]
    result = []
    for i in range(8):
        a = rgba.copy()
        a[owner_map != i] = 0
        pose = Image.fromarray(a)
        box = pose.getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < pose.width and box[3] < pose.height, 'Clipped source artwork'
        result.append((pose.crop(box), box))
    return result


def prepare(name):
    source = Image.open(WORK / 'raw' / (name + '.png'))
    poses = extract_poses(key_magenta(source))
    first, first_box = poses[0]
    factor = 300 / first.height
    source_cell = source.width / 4
    # The soles, not the sword or cape, establish the registration origin.
    first_array = np.asarray(first)
    sole_band = first_array[-40:]
    bronze = (sole_band[:, :, 3] > 200) & (sole_band[:, :, 0].astype(float) > sole_band[:, :, 2] * .9)
    xs = np.nonzero(bronze)[1]
    origin_x = first_box[0] + float(np.median(xs))
    if name == 'walk':
        # Extended contact foot biases the sole median; align torso/belt to Idle.
        # One measured translation for the entire cycle, preserving each stride.
        origin_x += 36 / factor
    frames, entries = [], []
    for i, (pose, box) in enumerate(poses):
        # One scale per animation, never one scale per pose; death remains collapsed.
        resized = pose.resize((round(pose.width * factor), round(pose.height * factor)), Image.Resampling.LANCZOS)
        px = round(ANCHOR[0] + (box[0] - (i % 4) * source_cell - origin_x) * factor)
        py = ANCHOR[1] - resized.height
        frame = Image.new('RGBA', (SIZE, SIZE))
        assert px >= 16 and py >= 16 and px + resized.width <= SIZE - 16, (name, i, px, py, resized.size)
        frame.alpha_composite(resized, (px, py))
        pixels = np.array(frame)
        residue = (pixels[:, :, 0].astype(float) > pixels[:, :, 1] + 35.0) & (pixels[:, :, 2].astype(float) > pixels[:, :, 1] + 35.0)
        pixels[:, :, 0][residue] = np.minimum(pixels[:, :, 0][residue], pixels[:, :, 1][residue].astype(float) + 20).astype(np.uint8)
        frame = Image.fromarray(pixels)
        bb = frame.getbbox()
        margin = min(bb[0], bb[1], SIZE - bb[2], SIZE - bb[3])
        assert margin >= 16 and frame.mode == 'RGBA'
        a = np.asarray(frame)
        magenta_left = ((a[:, :, 0].astype(float) - a[:, :, 1]) > 75) & ((a[:, :, 2].astype(float) - a[:, :, 1]) > 75) & (a[:, :, 3] > 100)
        assert int(magenta_left.sum()) == 0, (name, i, 'Chroma background remains', int(magenta_left.sum()), a[magenta_left][:5].tolist())
        entries.append({'frame': i, 'source_bbox': box, 'bbox': bb, 'minimum_margin': margin, 'scale': factor})
        frames.append(frame)
    return frames, entries


def resource():
    text = [f'[gd_resource type="SpriteFrames" load_steps={1 + 9 * len(NAMES)} format=3]', '']
    for name in NAMES:
        text.append(f'[ext_resource type="Texture2D" path="res://Sprites/monsters/generated/chapter3/war_wraith_animations/{name}.png" id="{name}"]')
    for name in NAMES:
        for i in range(8):
            text += ['', f'[sub_resource type="AtlasTexture" id="{name}_{i}"]', f'atlas = ExtResource("{name}")', f'region = Rect2({(i % 4)*SIZE}, {(i // 4)*SIZE}, {SIZE}, {SIZE})', 'filter_clip = true']
    animations = []
    # MonsterBase requests Run for movement; it must use the authored walk cycle.
    for title, name, speed, loop in [('Idle','idle',8,True), ('Walk','walk',10,True), ('Attack','attack',10,False), ('Hit','hit',18,False), ('Die','die',8,False), ('Run','walk',10,True), ('Skill','attack',8,False)]:
        durations = [1] * 8
        if title == 'Attack':
            durations[-1] = 2  # Existing .4 s windup + .5 s tail, impact begins at frame 4.
        frames = ',\n'.join('{"duration": %.1f, "texture": SubResource("%s_%d")}' % (durations[i],name,i) for i in range(8))
        animations.append('{\n"frames": [' + frames + '],\n"loop": ' + str(loop).lower() + ',\n"name": &"' + title + '",\n"speed": %.1f\n}' % speed)
    text += ['', '[resource]', 'animations = [' + ',\n'.join(animations) + ']']
    target = ROOT / 'data/sprites/monsters/war_wraith_frames.tres'
    backup = WORK / 'war_wraith_frames.before.tres'
    if not backup.exists():
        backup.write_bytes(target.read_bytes())
    target.write_text('\n'.join(text) + '\n', encoding='utf-8')


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (WORK / 'frames').mkdir(parents=True, exist_ok=True)
    report = {'frame_size': [SIZE, SIZE], 'anchor': ANCHOR, 'animations': {}}
    all_frames = {}
    combined = Image.new('RGBA', (SIZE * 8, SIZE * len(NAMES)))
    review = Image.new('RGB', (SIZE * 4, (SIZE + 40) * len(NAMES)), '#101827')
    draw = ImageDraw.Draw(review)
    for row, name in enumerate(NAMES):
        frames, entries = prepare(name)
        all_frames[name] = frames
        report['animations'][name] = entries
        sheet = Image.new('RGBA', (SIZE * 4, SIZE * 2))
        for i, frame in enumerate(frames):
            sheet.alpha_composite(frame, ((i % 4)*SIZE, (i // 4)*SIZE))
            combined.alpha_composite(frame, (i*SIZE, row*SIZE))
            frame.save(WORK / 'frames' / f'{name}_{i+1:02}.png')
        sheet.save(DEST / (name + '.png'))
        for col, i in enumerate([0, 2, 4, 7]):
            background = '#ecedf1' if col % 2 else '#101827'
            tile = Image.new('RGB', (SIZE, SIZE), background)
            tile.paste(frames[i], mask=frames[i].getchannel('A'))
            review.paste(tile, (col*SIZE, row*(SIZE+40)+40))
            draw.text((col*SIZE+14, row*(SIZE+40)+12), f'{name.upper()} / {i+1:02}', fill='white')
        print(name, '8 frames; margins:', [e['minimum_margin'] for e in entries], flush=True)
    combined.save(DEST / f'war_wraith_{8 * len(NAMES)}.png')
    review.save(WORK / 'alpha_review.png')
    # Portable animated review. RGBA source PNGs are the game deliverables.
    frames = []
    for tick in range(80):
        canvas = Image.new('RGB', (1024, 540 * ((len(NAMES)+1)//2)), '#141c2b')
        painter = ImageDraw.Draw(canvas)
        for j, name in enumerate(NAMES):
            i = (tick // 2) % 12
            i = i % 8 if name in ('idle', 'walk') else min(i, 7)
            canvas.paste(all_frames[name][i], ((j%2)*512, (j//2)*540+28), all_frames[name][i])
            painter.text(((j%2)*512+20,(j//2)*540+10), name.upper(), fill='white')
        frames.append(canvas)
    frames[0].save(WORK / 'animation_preview.webp', save_all=True, append_images=frames[1:], duration=75, loop=0, quality=85)
    (WORK / 'validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    resource()


if __name__ == '__main__':
    main()
