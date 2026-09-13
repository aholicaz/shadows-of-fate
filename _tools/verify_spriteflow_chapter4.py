"""Validate installed bytes, transparency, preserved gameplay fields, and runtime audits."""
import hashlib
import json
import re
import sys
from PIL import Image
from import_spriteflow_chapter4 import CONFIG, pipeline
if '--extra' in sys.argv:
    from import_spriteflow_chapter4_extra import CONFIG

ROOT, WORK = pipeline.ROOT, pipeline.WORK
VISUAL = ('fit_fixed_anchor_enabled', 'fit_fixed_anchor', 'fit_uniform_scale', 'fit_animation_scales')

def gameplay(path):
    text = path.read_text(encoding='utf-8-sig')
    for key in VISUAL:
        text = re.sub(r'^' + key + r' = .*?(?=^[A-Za-z_]\w* = |^\[|\Z)', '', text, flags=re.M | re.S)
    text = re.sub(r' uid="[^"]+"', '', text)
    return [line for line in text.splitlines() if line.strip()]

report = {}
for mid in CONFIG:
    manifest = json.loads((WORK / f'{mid}_manifest.json').read_text())
    relative = f'data/monsters/{mid}.tres'
    baseline = WORK / 'chapter4_extra/before' / f'{mid}.data.tres' if '--extra' in sys.argv else WORK / 'before' / relative
    assert gameplay(ROOT / relative) == gameplay(baseline), mid
    seen, edges = set(), []
    for anim in manifest['animations'].values():
        for frame in anim['frames']:
            key = (anim['source'], frame)
            if key in seen: continue
            seen.add(key)
            filename = f'frame_{frame:02}.png'
            source = WORK / 'downloads' / key[0] / filename
            installed = ROOT / 'Sprites/monsters/spriteflow' / mid / key[0] / filename
            assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256(installed.read_bytes()).digest()
            with Image.open(installed) as image:
                alpha = image.getchannel('A')
                assert alpha.getextrema() == (0, 255)
                bounds = alpha.point(lambda a: 255 if a > 20 else 0).getbbox()
                assert bounds
                if bounds[0] == 0 or bounds[1] == 0 or bounds[2] == image.width or bounds[3] == image.height:
                    edges.append({'source': key[0], 'frame': frame})
    audit = json.loads((WORK / 'runtime' / mid / 'audit.json').read_text())
    assert not audit['failures']
    assert len(seen) == manifest['unique_frames']
    report[mid] = {'unchanged_pngs': len(seen), 'gameplay_preserved': True, 'runtime_checks': audit['checks'], 'source_edge_contact': edges}
destination = WORK / ('chapter4_extra' if '--extra' in sys.argv else 'chapter4')
destination.mkdir(exist_ok=True)
(destination / 'validation.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
