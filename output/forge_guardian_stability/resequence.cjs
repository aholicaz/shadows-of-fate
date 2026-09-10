const fs = require('fs');
const path = 'data/sprites/monsters/forge_guardian_frames.tres';
let text = fs.readFileSync(path, 'utf8');
const animations = /\{\s*"frames": \[([\s\S]*?)\],\s*"loop": ([^,]+),\s*"name": &"([^"]+)",\s*"speed": ([\d.]+)\s*\}/g;
const blocks = [...text.matchAll(animations)];
const attack = blocks.find(m => m[3] === 'Attack');
const attackIds = [...attack[1].matchAll(/SubResource\("([^"]+)"\)/g)].map(m => m[1]);
const die = blocks.find(m => m[3] === 'Die');
const dieIds = [...die[1].matchAll(/SubResource\("([^"]+)"\)/g)].map(m => m[1]);
if (attackIds.length !== 32 || dieIds.length !== 8) throw Error('Unexpected authored frames');
// Original death sheet is 8 x 4 cells of 512, not 4 x 2 cells of 512 x 576.
for (let i = 0; i < 8; i++) {
 const pattern = new RegExp('(\\[sub_resource type="AtlasTexture" id="'+dieIds[i]+'"\\]\\s*atlas = ExtResource\\("2_jo0xi"\\)\\s*region = )Rect2\\([^)]+\\)');
 if (!pattern.test(text)) throw Error('Missing death atlas '+dieIds[i]);
 text = text.replace(pattern, '$1Rect2('+(i%8*512)+', 0, 512, 512)');
}
let extra = '';
for (let i = 8; i < 16; i++) {
 const id = 'AtlasTexture_forge_die_'+i;
 dieIds.push(id);
 extra += '[sub_resource type="AtlasTexture" id="'+id+'"]\natlas = ExtResource("2_jo0xi")\nregion = Rect2('+(i%8*512)+', 512, 512, 512)\n\n';
}
text = text.replace('[resource]', extra+'[resource]');
const skillIndices = Array.from({length:16},(_,i)=>i);
for(let hit=0;hit<4;hit++) skillIndices.push(14,13,12,13,14,15);
skillIndices.push(...Array.from({length:16},(_,i)=>i+16));
const make = (ids,name,fps) => '{\n"frames": [' + ids.map(id => '{\n"duration": 1.0,\n"texture": SubResource("'+id+'")\n}').join(', ') + '],\n"loop": false,\n"name": &"'+name+'",\n"speed": '+fps+'.0\n}';
text = text.replace(animations,(whole,body,loop,name) => name==='Skill' ? make(skillIndices.map(i=>attackIds[i]),name,20) : name==='Die' ? make(dieIds,name,12) : whole);
fs.writeFileSync(path,text);
console.log(JSON.stringify({skill_frames:skillIndices.length,impact_frames:skillIndices.flatMap((v,i)=>v===15?[i]:[]),death_frames:dieIds.length}));
