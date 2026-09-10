const fs=require('fs'),path=require('path');
const specs=JSON.parse(fs.readFileSync(path.join(__dirname,'specs.json'),'utf8').replace(/^\uFEFF/,''));
const regs=JSON.parse(fs.readFileSync(path.join(__dirname,'registration.json'),'utf8').replace(/^\uFEFF/,''));
const marks=JSON.parse(fs.readFileSync(path.join(__dirname,'marks.json'),'utf8').replace(/^\uFEFF/,''));
const v=a=>'PackedVector2Array('+a.flat().map(x=>Math.round(x)).join(', ')+')';
const rect=a=>'Array[Rect2](['+a.map(r=>'Rect2('+r.map(x=>Math.round(x)).join(', ')+')').join(', ')+'])';
const result={platform:{width:1981,height:597,top:36}};
for(const s of specs){
 const ox=s.id==='dark_forest_2'?-85:-100,oy=s.id==='nidavellir_town'?-13:s.id==='dark_forest_2'?-104:-200;
 function point(i,x,y){
  const b=fs.readFileSync(path.join(__dirname,`sources/${s.id}_${i}.png`));
  const iw=b.readUInt32BE(16),ih=b.readUInt32BE(20);
  const start=Math.round(s.step*i),end=i===s.n-1?s.w:Math.round(s.step*i+s.tileW);
  const [back,lip]=regs[s.id][i],tl=Math.round(s.floor+s.lip_offset),tb=tl-s.walk_depth;
  const yy=y<back?y*tb/back:y<lip?tb+(y-back)*(tl-tb)/(lip-back):tl+(y-lip)*(s.h-tl)/(ih-lip);
  return [ox+start+x*(end-start)/iw,oy+yy];
 }
 function region(a){const [i,x,y,w,h]=a,p=point(i,x,y),q=point(i,x+w,y+h);return [...p,q[0]-p[0],q[1]-p[1]]}
 const floor=s.floor+oy;
 const areas=[];for(let x=100;x<s.w-400;x+=1200)areas.push([x,floor-450,1000,370]);
 const fx={mote_regions:rect(areas),motes_per_region:'12',mote_color:'Color(0.62, 0.83, 0.61, 0.4)',mote_drift:'Vector2(10, -5)'};
 const m=marks[s.id];
 if(m.lamps?.length){fx.lantern_positions=v(m.lamps.map(p=>point(...p)));fx.flame_size='Vector2(18, 36)';fx.light_radius='180.0';fx.light_energy='0.16'}
 if(m.glows?.length){fx.glow_positions=v(m.glows.map(p=>point(...p)));fx.glow_radius='115.0';fx.glow_energy='0.12';fx.glow_color='Color(0.42, 0.7, 0.9, 0.22)'}
 for(const [key,kind] of [['water','water_regions'],['wind','wind_regions'],['heat','heat_regions']])if(m[key]?.length)fx[kind]=rect(m[key].map(region));
 if(s.id==='silver_marsh'){
  fx.mist_regions=rect([[0,floor-280,s.w,230],[400,floor-550,s.w-800,260]]);
  fx.mist_color='Color(0.61, 0.72, 0.77, 0.17)';fx.mote_color='Color(0.6, 0.85, 0.94, 0.45)';fx.mote_drift='Vector2(8, -3)';
 }else if(s.id==='dark_forest_2'){
  fx.mist_regions=rect([[0,floor-150,4200,130]]);fx.mist_color='Color(0.28, 0.37, 0.62, 0.1)';fx.mote_color='Color(0.6, 0.42, 1, 0.55)';fx.glow_color='Color(0.5, 0.25, 0.95, 0.22)';
  fx.shaft_positions=v([[730,-95],[2300,-95],[3600,-95]]);fx.shaft_size='Vector2(330, 790)';fx.shaft_color='Color(0.45, 0.57, 1.0, 0.09)';
 }else if(s.id==='root_road'||s.id==='vanir_town'){
  fx.shaft_positions=v(s.id==='root_road'?[[700,-190],[2000,-190],[3400,-190],[4600,-190]]:[[500,-190],[2000,-190],[3300,-190]]);
  fx.shaft_size='Vector2(400, 1050)';fx.shaft_color='Color(0.86, 0.89, 0.65, 0.065)';
 }else if(s.id==='withered_grove'){
  fx.mote_color='Color(0.68, 0.57, 0.36, 0.32)';fx.mote_drift='Vector2(18, 9)';fx.mist_regions=rect([[100,floor-180,s.w-200,150]]);fx.mist_color='Color(0.59, 0.58, 0.52, 0.09)';
 }else if(s.id==='forgotten_battlefield'){
  fx.mote_color='Color(0.61, 0.59, 0.6, 0.28)';fx.mote_drift='Vector2(24, 3)';fx.mist_regions=rect([[0,floor-220,s.w,180]]);fx.mist_color='Color(0.54, 0.49, 0.58, 0.1)';
 }else if(s.id==='spring_of_life'){
  fx.mote_color='Color(0.38, 0.7, 0.68, 0.3)';fx.mist_regions=rect([[0,floor-200,s.w,180]]);fx.mist_color='Color(0.26, 0.48, 0.49, 0.1)';fx.drifting_embers='true';
 }else if(s.id==='nidavellir_town'){
  fx.mote_regions='Array[Rect2]([])';fx.drifting_embers='true';fx.light_radius='200.0';fx.light_energy='0.2';
 }
 const lore={};for(const [n,p] of Object.entries(m.lore||{})){lore[n]=[Math.round(point(...p)[0]),Math.round(floor-80)]}
 result[s.id]={fx,lore};
 if(m.rune)result[s.id].quest_fx={rune_regions:rect(m.rune.map(region)),rune_color:'Color(0.35, 0.88, 0.81, 0.4)',rune_unlock_flag:'&"killed_gullveig_ember"'};
}
fs.writeFileSync(path.join(__dirname,'layout.json'),JSON.stringify(result,null,2));
