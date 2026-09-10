const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../..');
const specs = JSON.parse(fs.readFileSync(path.join(__dirname, 'specs.json'), 'utf8'));
const layout = JSON.parse(fs.readFileSync(path.join(__dirname, 'layout.json'), 'utf8'));
function set(block, key, value) {
  const re = new RegExp('^' + key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ' = .*$', 'm');
  return re.test(block) ? block.replace(re, key + ' = ' + value) : block.trimEnd() + '\n' + key + ' = ' + value + '\n\n';
}
for (const s of specs) {
  const file = path.join(root, 'scenes/maps', s.id + '.tscn');
  let text = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  let blocks = text.split(/(?=^\[(?:node|sub_resource|ext_resource) )/m);
  const findNode = (name, parent) => blocks.findIndex(b => b.startsWith(`[node name="${name}" `) && (parent === undefined || b.split('\n')[0].includes(`parent="${parent}"`)));
  const edit = (name, parent, props) => { const i = findNode(name, parent); if(i < 0) throw Error('Missing node '+s.id+'/'+name); for(const [k,v] of Object.entries(props)) blocks[i] = set(blocks[i],k,v); };
  let tex = blocks.findIndex(b => b.startsWith('[ext_resource type="Texture2D"') && b.includes('id="bg38"'));
  const texLine = `[ext_resource type="Texture2D" path="res://Sprites/map/generated/${s.id}_bg_final.png" id="bg38"]\n\n`;
  if(tex < 0) blocks.splice(1,0,texLine); else blocks[tex] = texLine;
  if(!blocks.some(b => b.startsWith('[ext_resource') && b.includes('id="ambient_fx"'))) blocks.splice(1,0,'[ext_resource type="Script" path="res://scripts/world/map_ambient_fx.gd" id="ambient_fx"]\n\n');
  const ox = s.id === 'dark_forest_2' ? -85 : -100;
  const oy = s.id === 'nidavellir_town' ? -13 : s.id === 'dark_forest_2' ? -104 : -200;
  const floor = s.floor + oy;
  const poly = `PackedVector2Array(0, 0, ${s.w}, 0, ${s.w}, ${s.h}, 0, ${s.h})`;
  edit('Map', undefined, {map_bounds:`Rect2(${ox}, ${oy}, ${s.w}, ${s.h})`});
  edit('Sky','Background',{position:`Vector2(${ox}, ${oy})`,texture:'ExtResource("bg38")',color:'Color(1, 1, 1, 1)',polygon:poly,uv:poly,texture_filter:'2'});
  edit('FarLayer','Background',{visible:'false'});
  edit('Visual','Terrain/Ground',{visible:'false'});
  if(s.id === 'nidavellir_town') {
    const gi = blocks.findIndex(b=>b.startsWith('[sub_resource type="RectangleShape2D" id="Rect_ground"]'));
    blocks[gi] = set(blocks[gi], 'size', 'Vector2(5800, 177)');
    edit('Ground','Terrain',{position:'Vector2(2700, 1000)'});
    const npcs={Helga:550,Dvalin:1350,Brokk:2200,SavePoint:3050,Healer:3850,Hans:4550};
    for(const [n,x] of Object.entries(npcs)) edit(n,'NPCs',{position:`Vector2(${x}, ${floor-60})`});
    edit('from_mine','SpawnPoints',{position:`Vector2(5200, ${floor-100})`});
    edit('ToMine','Portals',{position:`Vector2(5340, ${floor-30})`});
    edit('ToRoad','Portals',{position:`Vector2(60, ${floor-30})`});
    edit('SindriGrave','Lore',{position:`Vector2(5000, ${floor-80})`});
  }
  if(s.id === 'dark_forest_2') edit('AltarStone','Lore',{position:`Vector2(2850, ${floor-80})`});
  if(s.id === 'vanir_town') {
    for(const [n,x] of Object.entries({Eskil:1100,Sifa:1650,Galla:2000,SavePoint:2380,Leif:2950,Arvid:3350,Frida:3570})) edit(n,'NPCs',{position:`Vector2(${x}, ${floor-60})`});
  }
  // Adjust only interaction markers to the final painted landmark locations.
  for(const [n,p] of Object.entries(layout[s.id].lore || {})) edit(n,'Lore',{position:`Vector2(${p[0]}, ${p[1]})`});
  // Retain every authored collision platform and replace its mockup rectangle with textured root ledge art.
  const platforms = blocks.filter(b=>/^\[node name="Plat\d+" type="StaticBody2D" parent="Terrain"/.test(b));
  if(platforms.length) {
    blocks.splice(1,0,'[ext_resource type="Texture2D" path="res://Sprites/map/generated/root_ledge.png" id="root_ledge"]\n\n');
    for(const block of platforms) {
      const n = block.match(/name="([^"]+)"/)[1];
      const shapeBlock = blocks[findNode('Shape','Terrain/'+n)];
      const shapeID = shapeBlock.match(/SubResource\("([^"]+)"\)/)[1];
      const shape = blocks.find(b=>b.startsWith('[sub_resource')&&b.split('\n')[0].includes(`id="${shapeID}"`));
      const [w,h] = shape.match(/size = Vector2\(([^,]+), ([^)]+)\)/).slice(1).map(Number);
      edit('Visual','Terrain/'+n,{visible:'false'});
      const a = layout.platform;
      const height = w * a.height / a.width;
      blocks.push(`[node name="RootLedge" type="Sprite2D" parent="Terrain/${n}"]\ntexture = ExtResource("root_ledge")\ncentered = false\nposition = Vector2(${-w/2}, ${-h/2-a.top*height/a.height})\nscale = Vector2(${w/a.width}, ${height/a.height})\ntexture_filter = 2\n\n`);
    }
  }
  const fx = layout[s.id].fx;
  blocks.push('[node name="AmbientFX" type="Node2D" parent="."]\nscript = ExtResource("ambient_fx")\n'+Object.entries(fx).map(([k,v])=>`${k} = ${v}`).join('\n')+'\n\n');
  if(layout[s.id].quest_fx) blocks.push('[node name="QuestRuneFX" type="Node2D" parent="."]\nscript = ExtResource("ambient_fx")\n'+Object.entries(layout[s.id].quest_fx).map(([k,v])=>`${k} = ${v}`).join('\n')+'\n');
  text = blocks.join('');
  const loads = (text.match(/^\[(?:ext_resource|sub_resource) /gm)||[]).length+1;
  text = text.replace(/^\[gd_scene[^\n]*\]/, m=>m.replace(/ load_steps=\d+/, '').replace('[gd_scene', '[gd_scene load_steps='+loads));
  fs.writeFileSync(file,text,'utf8');
  console.log(s.id, s.w, s.h, 'floor',floor, 'platforms',platforms.length);
}
