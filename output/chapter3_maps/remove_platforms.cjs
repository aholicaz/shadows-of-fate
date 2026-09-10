const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../..');
const dir = path.join(root, 'scenes/maps');
const backup = path.join(__dirname, 'before_no_platforms');
fs.mkdirSync(backup, {recursive:true});
for(const name of fs.readdirSync(dir).filter(n=>n.endsWith('.tscn'))) {
  const file = path.join(dir,name), original = fs.readFileSync(file,'utf8');
  let blocks = original.split(/(?=^\[(?:node|sub_resource|ext_resource) )/m);
  const platforms = blocks.filter(b=>/^\[node name="Plat\d+" type="StaticBody2D" parent="Terrain"/.test(b));
  if(!platforms.length) continue;
  if(!fs.existsSync(path.join(backup,name))) fs.writeFileSync(path.join(backup,name),original);
  const names = platforms.map(b=>b.match(/name="([^"]+)"/)[1]);
  blocks = blocks.filter(b=>!names.some(n=>b.startsWith(`[node name="${n}" `) || b.split('\n')[0].includes(`parent="Terrain/${n}"`) || b.split('\n')[0].includes(`parent="Terrain/${n}/`)));
  let text = blocks.join('');
  blocks = blocks.filter(b=> {
    if(!b.startsWith('[sub_resource') && !b.startsWith('[ext_resource')) return true;
    const id = b.split('\n')[0].match(/ id="([^"]+)"/)[1];
    return text.includes((b.startsWith('[sub_resource')?'SubResource':'ExtResource')+'("'+id+'")');
  });
  text = blocks.join('').replace(/load_steps=\d+/, 'load_steps='+((blocks.filter(b=>/^\[(?:ext_resource|sub_resource) /.test(b)).length)+1));
  fs.writeFileSync(file,text);
  console.log(name+': removed '+names.join(', '));
}
