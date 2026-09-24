"""Fail if production resources refer to excluded developer-only files."""
from pathlib import Path
import re, fnmatch
root=Path(__file__).resolve().parents[1]
preset=(root/'export_presets.cfg').read_text(encoding='utf-8')
patterns=[s.strip().lower() for s in re.search(r'exclude_filter="([^"]*)"',preset)[1].split(',')]
def excluded(path):
    return any(fnmatch.fnmatch(path.lower(),p) for p in patterns)
errors=[]
for folder in ['scripts/core','scripts/ui','scripts/world','scripts/entities','scripts/resources','scenes','data']:
    for source in (root/folder).rglob('*'):
        rel=source.relative_to(root).as_posix()
        if source.suffix not in ['.gd','.tscn','.tres'] or excluded(rel):continue
        for target in re.findall(r'res://([^"\n]+)',source.read_text(encoding='utf-8')):
            # Video paths are optional strings, intentionally disabled in the Web preset.
            if excluded(target) and not target.endswith((".ogv", ".mp4")):errors.append(f'{rel} -> {target}')
if errors:raise SystemExit('Export excludes production dependency:\n'+'\n'.join(errors))
print('EXPORT_BOUNDARIES_PASS: production resource references do not point into excluded test/output paths')
