"""Prepare user-authorized green-screen single monster portraits, not animations."""
from pathlib import Path
import json
import shutil
import zipfile
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'output/chapter4_monsters'
DEST = ROOT / 'Sprites/monsters/concepts/chapter4'

def main():
    manifest = json.loads((WORK / 'sources.json').read_text(encoding='utf-8'))
    DEST.mkdir(parents=True, exist_ok=True)
    (WORK / 'originals').mkdir(exist_ok=True)
    review = Image.new('RGB', (1600, 1000), '#202b3c')
    draw = ImageDraw.Draw(review)
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)
    checks = []
    for i, spec in enumerate(manifest):
        source = Path(spec['source'])
        shutil.copy2(source, WORK / 'originals' / (spec['id'] + '.png'))
        im = Image.open(source).convert('RGB')
        rgb = np.asarray(im, dtype=np.float32)
        excess = rgb[:, :, 1] - np.maximum(rgb[:, :, 0], rgb[:, :, 2])
        alpha = np.clip((170.0 - excess) / 140.0, 0, 1)
        alpha[alpha < .02] = 0
        clean = rgb.copy()
        # Remove residual key spill only on soft contour pixels.
        edge = (alpha > 0) & (alpha < 1)
        clean[:, :, 1][edge] = np.minimum(clean[:, :, 1][edge], np.maximum(clean[:, :, 0][edge], clean[:, :, 2][edge]))
        clean[alpha == 0] = 0
        out = Image.fromarray(np.dstack([clean.astype('uint8'), np.rint(alpha*255).astype('uint8')]), 'RGBA')
        # Keep native resolution and pose. Add a small clear margin if art is near edges.
        canvas = Image.new('RGBA', (out.width+128, out.height+128))
        canvas.alpha_composite(out, (64, 64))
        canvas.save(DEST / (spec['id'] + '.png'))
        bounds = canvas.getbbox()
        assert bounds and bounds[0] >= 64 and bounds[1] >= 64
        assert np.count_nonzero(alpha == 0) > alpha.size*.08
        assert np.count_nonzero(alpha > .95) > alpha.size*.1
        checks.append(dict(id=spec['id'], size=canvas.size, bounds=bounds, transparent_fraction=float(np.mean(alpha == 0))))
        thumb = canvas.copy()
        thumb.thumbnail((390, 430), Image.Resampling.LANCZOS)
        x = (i % 4)*400 + (400-thumb.width)//2
        y = (i // 4)*500 + (450-thumb.height)//2
        review.paste(thumb, (x,y), thumb)
        draw.text(((i%4)*400+20,(i//4)*500+465), spec['id'], fill='white', font=font)
    review.save(WORK / 'chapter4_roster.jpg', quality=94)
    (WORK / 'alpha_checks.json').write_text(json.dumps(checks, indent=2), encoding='utf-8')
    with zipfile.ZipFile(WORK / 'chapter4_monsters_png.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for spec in manifest:
            z.write(DEST / (spec['id']+'.png'), spec['id']+'.png')
        z.write(WORK / 'README.md', 'README.md')
    print(json.dumps(checks, indent=2))

if __name__ == '__main__':
    main()
