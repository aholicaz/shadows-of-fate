"""Copy generated artwork unchanged; let Godot's importer size UI textures."""
from pathlib import Path
import hashlib
import json
import re
import shutil
from PIL import Image

root = Path(__file__).resolve().parents[1]
if (root / 'output/balance_v2/alpha_report.json').exists():
    raise SystemExit('V2 transparent icons are installed. This historical V1 installer must not overwrite them.')
manifest = json.loads((root / 'output/balance/icon_manifest.json').read_text(encoding='utf-8'))
for entry in manifest:
    skill_id = entry['id']
    source = Path(entry['source'])
    with Image.open(source) as im:
        assert im.width == im.height and im.width >= 256
        entry['source_size'] = list(im.size)
        entry['source_mode'] = im.mode
    target = root / f'Sprites/skill_icons/{skill_id}.png'
    shutil.copy2(source, target)
    resource_path = f'res://Sprites/skill_icons/{skill_id}.png'
    imported = f'res://.godot/imported/{skill_id}.png-{hashlib.md5(resource_path.encode()).hexdigest()}.ctex'
    target.with_suffix('.png.import').write_text(f'''[remap]
importer="texture"
type="CompressedTexture2D"
path="{imported}"

[deps]
source_file="{resource_path}"
dest_files=["{imported}"]

[params]
compress/mode=0
mipmaps/generate=true
process/size_limit=256
process/fix_alpha_border=true
detect_3d/compress_to=0
''', encoding='utf-8')
    skill = root / f'data/skills/{skill_id}.tres'
    data = skill.read_text(encoding='utf-8')
    data, count = re.subn(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="i"\])', lambda m: m[1]+resource_path+m[2], data)
    assert count == 1, skill_id
    skill.write_text(data, encoding='utf-8')
    entry['asset'] = resource_path
    entry['import_size_limit'] = 256
    print(skill_id, entry['source_size'], entry['source_mode'])
(root / 'output/balance/icon_manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
