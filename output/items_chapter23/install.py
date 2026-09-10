from pathlib import Path
import json, shutil, re, html
from PIL import Image
root=Path.cwd(); out=root/'output/items_chapter23'
rows=json.loads((out/'manifest.json').read_text(encoding='utf-8'))
backup=out/'resource_backup'; backup.mkdir(exist_ok=True)
for row in rows:
    name=row['id']; src=out/'ready'/(name+'.png')
    with Image.open(src) as im:
        assert im.size==((640,960) if name.startswith('card_') else (256,256))
        assert im.getchannel('A').getextrema()==(0,255), name
    shutil.copy2(src,root/'Sprites/items/placeholder'/src.name)
    if row.get('existing_card'):
        p=root/'data/cards'/(name+'.tres')
        if not (backup/p.name).exists(): shutil.copy2(p,backup/p.name)
        text=p.read_text(encoding='utf-8')
        text=re.sub(r'\[ext_resource type="Texture2D"[^\n]*id="art_1"\]', '[ext_resource type="Texture2D" path="res://Sprites/items/placeholder/'+name+'.png" id="art_1"]',text)
        p.write_text(text,encoding='utf-8')
cards=''.join('<figure><img src="ready/'+r['id']+'.png"><figcaption>'+html.escape(r['id'])+'</figcaption></figure>' for r in rows)
(out/'gallery.html').write_text('<!doctype html><meta charset="utf-8"><title>Chapter 2–3 assets</title><style>body{background:#242a33;color:white;font:14px sans-serif}main{display:flex;flex-wrap:wrap}figure{width:180px;margin:12px;text-align:center}img{width:160px;height:240px;object-fit:contain;background:repeating-conic-gradient(#414853 0% 25%,#343b45 0% 50%) 0/20px 20px}figcaption{margin-top:8px}</style><h1>55 item and card assets</h1><main>'+cards+'</main>',encoding='utf-8')
print('Installed and alpha-validated',len(rows),'assets; updated 7 existing-card illustration paths')
