"""User-authorized checkerboard removal; never overwrites generated sources."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageFilter, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/boss_skills'
DEST = ROOT / 'Sprites/effects/boss_skills'
manifest = json.loads((OUT / 'source_manifest.json').read_text(encoding='utf-8'))
manifest.update(json.loads((OUT / 'final_sources.json').read_text(encoding='utf-8')))
report = {}
for name, entry in manifest.items():
    im = Image.open(entry['source']).convert('RGBA')
    a = np.array(im).astype(np.float32)
    if entry.get('background') == 'black':
        rgb = a[:,:,:3]
        value = rgb.max(axis=2)
        alpha = np.clip((value-3)/67,0,1)
        barrier = Image.fromarray((value>65).astype('uint8')*255)
        flood = ImageOps.expand(barrier,border=1,fill=0)
        ImageDraw.floodfill(flood,(0,0),128)
        alpha[np.asarray(flood)[1:-1,1:-1]==0] = 1
        a[:,:,:3] = np.clip(rgb / np.maximum(alpha[:,:,None],.001),0,255)
        a[:,:,3] = alpha*255
    elif Image.open(entry['source']).mode != 'RGBA' or a[:,:,3].min() == 255:
        rgb = a[:,:,:3]
        chroma = rgb.max(axis=2) - rgb.min(axis=2)
        alpha = np.clip((chroma - 18) / 75, 0, 1)
        # Flood only exterior neutral pixels; enclosed white-hot veins stay solid.
        barrier = Image.fromarray(((chroma > 38) | (rgb.max(axis=2) < 110)).astype('uint8') * 255)
        flood = ImageOps.expand(barrier, border=1, fill=0)
        ImageDraw.floodfill(flood, (0,0), 128)
        interior = np.asarray(flood)[1:-1,1:-1] == 0
        # Large neutral islands can be baked checkerboard inside curled trails.
        # Preserve only small enclosed cores, not their entire neutral island.
        hot = Image.fromarray(((chroma>150) & (rgb[:,:,0]>220) & (rgb[:,:,1]>70)).astype('uint8')*255)
        near_hot = np.asarray(hot.filter(ImageFilter.MaxFilter(25))) > 0
        core = interior & near_hot & (chroma<35) & (rgb.min(axis=2)>140)
        alpha[core] = 1
        rgb[core] = (255,244,204)
        # Remove the neutral backdrop contribution in soft colored edges.
        neutral = rgb.min(axis=2)
        edge = alpha < .999
        rgb[edge] = (rgb[edge]-neutral[edge,None]) / np.maximum(chroma[edge,None],1) * rgb.max(axis=2)[edge,None]
        a[:,:,:3] = rgb
        a[:,:,3] = alpha*255
    clean = Image.fromarray(a.astype('uint8'))
    # Fixed common cell grid, no per-frame recentering or scaling.
    w,h = clean.size
    cw,ch = round(w/4),round(h/2)
    sheet = Image.new('RGBA',(cw*4,ch*2))
    for i in range(8):
        x,y = round((i%4)*w/4), round((i//4)*h/2)
        frame = clean.crop((x,y,min(x+cw,w),min(y+ch,h)))
        sheet.paste(frame,((i%4)*cw,(i//4)*ch))
    sheet.save(DEST / (name+'_sheet.png'), optimize=True)
    fps = 20 if name=='scythe' else (12 if name=='burning_ground' else 16)
    lines = ['[gd_resource type="SpriteFrames" load_steps=10 format=3]', '', '[ext_resource type="Texture2D" path="res://Sprites/effects/boss_skills/'+name+'_sheet.png" id="1"]','']
    for i in range(8):
        lines += ['[sub_resource type="AtlasTexture" id="Frame_'+str(i)+'"]','atlas = ExtResource("1")','region = Rect2(%s, %s, %s, %s)' % ((i%4)*cw,(i//4)*ch,cw,ch),'filter_clip = true','']
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("Frame_'+str(i)+'")}' for i in range(8))
    lines += ['[resource]','animations = [{"frames": ['+frames+'], "loop": '+('false' if name=='scythe' else 'true')+', "name": &"default", "speed": '+str(float(fps))+'}]']
    if name == 'burning_ground':
        baselines=[]
        for i in range(8):
            frame=np.asarray(sheet.crop(((i%4)*cw,(i//4)*ch,(i%4+1)*cw,(i//4+1)*ch)))
            solid=(frame[:,:,3]>180) & (frame[:,:,:3].max(axis=2)>100)
            rows=np.where(solid.sum(axis=1)>cw*.12)[0]
            baselines.append(float(rows[-1]) if len(rows) else float(ch))
        lines += ['metadata/baseline_y = PackedFloat32Array('+', '.join(map(str,baselines))+')']
    (DEST/(name+'_frames.tres')).write_text('\n'.join(lines)+'\n',encoding='utf-8')
    report[name]={'size':sheet.size,'cell':[cw,ch],'alpha':sheet.getchannel('A').getextrema(),'fps':fps,'unique_frames':len({sheet.crop(((i%4)*cw,(i//4)*ch,(i%4+1)*cw,(i//4+1)*ch)).tobytes() for i in range(8)})}
    for bg,color in [('dark',(18,25,40,255)),('light',(220,224,232,255))]:
        preview=Image.new('RGBA',sheet.size,color)
        preview.alpha_composite(sheet)
        preview.save(OUT/(name+'_'+bg+'.png'))
(OUT/'sheet_validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
