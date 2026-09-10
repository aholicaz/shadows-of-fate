from pathlib import Path
import json,shutil
from PIL import Image,ImageOps,ImageDraw,ImageFont,ImageChops
ROOT=Path.cwd(); OUT=ROOT/'output/items_chapter23'
manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
generated={r['id']:r for r in json.loads((OUT/'generations.json').read_text(encoding='utf-8'))}
for sub in ['originals','ready']:(OUT/sub).mkdir(exist_ok=True)

def card_mask():
    mask=Image.new('L',(2560,3840));d=ImageDraw.Draw(mask)
    d.rounded_rectangle((0,0,2559,3839),radius=100,fill=255)
    return mask.resize((640,960),Image.Resampling.LANCZOS)

def original_frame():
    frame=Image.open(ROOT/'Sprites/card/card_wolf.webp').convert('RGBA')
    mask=Image.new('L',frame.size);d=ImageDraw.Draw(mask)
    d.rectangle((0,0,639,959),fill=255)
    # Exact original border pixels retained. Remove only the illustrated interior.
    inner=[(65,27),(289,27),(320,57),(350,27),(575,27),(608,59),(623,91),(623,858),(606,902),(574,931),(350,931),(320,901),(290,931),(66,931),(31,903),(16,858),(16,90),(31,58)]
    d.polygon(inner,fill=0)
    frame.putalpha(ImageChops.multiply(mask,card_mask()))
    return frame

def compose_card(art,title):
    canvas=ImageOps.fit(art.convert('RGB'),(640,960),method=Image.Resampling.LANCZOS).convert('RGBA')
    canvas.alpha_composite(original_frame())
    d=ImageDraw.Draw(canvas)
    font_path='C:/Windows/Fonts/arialbd.ttf'
    size=59
    while True:
        font=ImageFont.truetype(font_path,size)
        if d.textbbox((0,0),title,font=font,stroke_width=3)[2]<555 or size<30:break
        size-=1
    d.text((43,46),title,font=font,fill=(8,9,13),stroke_width=3,stroke_fill=(239,243,244),anchor='lt')
    canvas.putalpha(card_mask())
    return canvas

report=[]
for row in manifest:
    name=row['id']; src=row.get('existing_card')
    if name in generated:src=generated[name]['source']
    if not src:continue
    src=Path(src)
    original=OUT/'originals'/(name+src.suffix)
    if not original.exists():shutil.copy2(src,original)
    pic=Image.open(src).convert('RGBA')
    if name.startswith('card_'):
        if row.get('existing_card'):
            pic=ImageOps.fit(pic,(640,960),method=Image.Resampling.LANCZOS)
            pic.putalpha(card_mask())
        else:pic=compose_card(pic,name[5:].replace('_',' ').title())
    else:
        if pic.getchannel('A').getextrema()[0]==255:
            print('OPAQUE_REQUIRES_FIX',name);continue
        # Trim alpha only, then add equal inventory padding. No stretching.
        bounds=pic.getchannel('A').getbbox()
        pic=ImageOps.contain(pic.crop(bounds),(224,224),method=Image.Resampling.LANCZOS)
        tile=Image.new('RGBA',(256,256));tile.alpha_composite(pic,((256-pic.width)//2,(256-pic.height)//2));pic=tile
    target=OUT/'ready'/(name+'.png')
    pic.save(target,optimize=True)
    report.append(dict(id=name,size=list(pic.size),bytes=target.stat().st_size,alpha=pic.getchannel('A').getextrema(),source=str(src)))
(OUT/'size_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('READY',len(report),'of',len(manifest),'bytes',sum(r['bytes'] for r in report))
# Visual QA sheet at actual inventory icon scale + larger previews.
thumbs=Image.new('RGB',(1100,((len(report)+5)//6)*160),(36,42,51));d=ImageDraw.Draw(thumbs)
for i,r in enumerate(report):
    pic=Image.open(OUT/'ready'/(r['id']+'.png'))
    pic.thumbnail((120,120),Image.Resampling.LANCZOS)
    x=(i%6)*183;y=(i//6)*160
    thumbs.paste(pic,(x+(160-pic.width)//2,y),pic)
    d.text((x+2,y+125),r['id'],fill='white')
thumbs.save(OUT/'gallery.jpg',quality=90)
