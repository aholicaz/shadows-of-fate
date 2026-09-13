"""Copy native idle frames; preserve original pixels and fixed registration."""
from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[1]
src=ROOT/'output/spriteflow/downloads/runeblade_idle'
dst=ROOT/'Sprites/player/runeblade/idle'
dst.mkdir(parents=True,exist_ok=True)
lines=['[gd_resource type="SpriteFrames" format=3]','']
for i in range(1,33):
    name=f'frame_{i:02}.png'
    shutil.copy2(src/name,dst/name)
    lines.append(f'[ext_resource type="Texture2D" path="res://Sprites/player/runeblade/idle/{name}" id="f{i}"]')
lines += ['','[resource]','animations = [{','"frames": [']
for i in range(1,33): lines.append(f'{{"duration": 1.0, "texture": ExtResource("f{i}")}},')
lines += ['], "loop": true, "name": &"Idle_Runeblade", "speed": 8.0','}]',
          'metadata/runeblade_idle_anchor = Vector2(560, 767)',
          'metadata/runeblade_idle_height = 694.0',
          'metadata/runeblade_idle_hand = Vector2(462, 435)','']
(ROOT/'data/sprites/runeblade_idle_frames.tres').write_text('\n'.join(lines),encoding='utf-8')
print('Runeblade idle: 32 original PNGs installed.')
