"""Measure attachment sockets against artist-edited PNGs; never writes image assets."""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/runeblade_skill_weapons'
# Hand hints measured on 240px-wide review thumbnails, in source frame order.
HINTS = {
 'rb_skill_2108': [(94,79),(94,79),(89,72),(105,85),(167,68),(168,66),(167,66),(153,76),(74,65),(82,62),(82,63),(81,62),(95,90),(158,83),(158,83),(158,83),(157,84),(145,52),(121,27),(120,25),(120,25),(109,51),(108,128),(109,128),(107,131),(108,131),(108,123),(98,101),(88,85),(94,80),(94,80),(94,80)],
 'rb_skill_2055': [(89,77),(89,77),(89,77),(108,76),(136,66),(155,82),(81,62),(85,62),(75,62),(72,67),(72,68),(80,38),(126,17),(126,18),(126,18),(126,18),(86,40),(92,132),(92,132),(92,132),(91,132),(91,132),(91,124),(88,108),(88,96),(88,86),(89,80),(89,79),(89,79),(89,79),(89,79),(89,79)],
 'rb_skill_2044': [(89,77),(89,77),(89,77),(78,76),(135,60),(135,61),(135,61),(70,64),(70,65),(70,65),(101,68),(135,57),(135,58),(69,70),(70,65),(70,65),(80,77),(133,62),(132,62),(101,65),(72,66),(71,66),(71,66),(71,66),(72,65),(72,65),(80,75),(93,79),(93,79),(93,79),(93,79),(93,79)],
 'rb_skill_2020': [(89,77),(89,77),(89,68),(94,65),(94,65),(81,79),(124,63),(121,61),(121,61),(117,65),(89,70),(95,64),(95,64),(82,80),(142,36),(145,36),(145,33),(133,29),(78,117),(78,117),(78,117),(78,117),(78,117),(78,117),(78,110),(78,98),(83,91),(89,81),(93,80),(93,80),(93,80),(93,80)],
}

def measure(source, index, hint):
    current = Image.open(ROOT / 'Sprites/player/runeblade' / source / f'frame_{index:02}.png').convert('RGBA')
    original = Image.open(ROOT / 'output/spriteflow/downloads' / source / f'frame_{index:02}.png').convert('RGBA')
    a, b = np.array(original).astype(float), np.array(current).astype(float)
    point = np.array(hint, dtype=float) * current.width / 240
    # Refine within the authored hand ROI using surviving warm finger pixels.
    yy, xx = np.indices(b.shape[:2])
    skin = (b[:,:,0]>110)&(b[:,:,1]>55)&(b[:,:,0]>b[:,:,1]*1.18)&(b[:,:,2]>b[:,:,1]*.58)&(b[:,:,2]<b[:,:,1]*1.03)&(b[:,:,3]>180)
    near = ((xx-point[0])**2+(yy-point[1])**2 < 16**2) & skin
    if near.sum() >= 4:
        point = np.array([xx[near].mean(),yy[near].mean()])
    removed = (a[:,:,3]>150)&(b[:,:,3]<50)
    coords = np.column_stack((xx[removed],yy[removed]))
    distances = np.linalg.norm(coords-point, axis=1)
    coords = coords[(distances>20)&(distances<430)]
    assert len(coords)>8, (source,index,'No removed sword pixels')
    distances = np.linalg.norm(coords-point,axis=1)
    tip = np.median(coords[distances >= np.percentile(distances,90)],axis=0)
    angle = math.degrees(math.atan2(*(tip-point)[::-1]))
    # Foreshortened overhead hold: deleted pixels include trailing ornament.
    if source == 'rb_skill_2108' and index in (20, 21):
        angle = 345.0
    return current, [round(float(point[0]),2),round(float(point[1]),2),round((angle-197+180)%360-180,1)]

if __name__ == '__main__':
    path = ROOT / 'data/sprites/runeblade_weapon_tracks.json'
    tracks = json.loads(path.read_text())
    for source, hints in HINTS.items():
        sheet = Image.new('RGB',(1920,1000),(36,43,54)); draw=ImageDraw.Draw(sheet)
        poses=[]
        for i,hint in enumerate(hints,1):
            current,pose=measure(source,i,hint);poses.append(pose)
            current.thumbnail((240,225)); x=(i-1)%8*240;y=(i-1)//8*250
            sheet.paste(current,(x,y),current)
            px=x+pose[0]*240/1112;py=y+pose[1]*240/1112
            angle=math.radians(pose[2]+197)
            draw.line((px,py,px+55*math.cos(angle),py+55*math.sin(angle)),fill='cyan',width=2)
            draw.ellipse((px-3,py-3,px+3,py+3),fill='red')
            draw.text((x+5,y+220),f'{i}: {pose}',fill='white')
        tracks[source]=poses
        sheet.save(OUT/f'{source}_sockets.jpg')
    path.write_text(json.dumps(tracks,indent=2)+'\n')
