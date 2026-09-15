"""Assemble real Godot render captures into a compact animated review artifact."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'output/boss_skills'
all_frames=[]
for kind in ('meteor','flame_jet','scythe'):
    files=sorted(out.glob(kind+'_[0-9][0-9][0-9].png'))
    frames=[Image.open(p).convert('RGB').resize((800,450),Image.Resampling.LANCZOS).quantize(colors=192) for p in files]
    assert frames, kind
    frames[0].save(out/(kind+'_preview.gif'),save_all=True,append_images=frames[1:],duration=[80 if i%3 else 90 for i in range(len(frames))],loop=0,optimize=False)
    all_frames+=frames
all_frames[0].save(out/'boss_skills_preview.gif',save_all=True,append_images=all_frames[1:],duration=[80 if i%3 else 90 for i in range(len(all_frames))],loop=0,optimize=False)
print('Preview frames:',len(all_frames),'bytes:',(out/'boss_skills_preview.gif').stat().st_size)
