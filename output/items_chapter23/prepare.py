from pathlib import Path
import json,re,shutil
from PIL import Image
ROOT=Path.cwd()
OUT=ROOT/'output/items_chapter23'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').write_text('')
names='silver_dust spectral_plume spring_vial spring_amulet storm_medal thorn_fang thorn_shield vanir_circlet vanir_seal withered_bark marsh_cutter root_sword aesir_warblade sentinel_blade card_bog_lurker card_gullveig_ember card_mist_sprite card_thorn_hound card_thorn_matriarch card_war_wraith card_vanir_sentinel card_withered_treant aesir_helm_rusted ash_ring bark_armor bog_bone card_root_crawler bramble_pelt carved_stone ember_heart eskil_chronicle ember_of_gullveig frida_song gullveig_ash heartwood_chip mist_cloak mist_essence matriarch_thorn root_boots pale_sap root_fiber royal_bloom sentinel_core sentinel_plate mole_claw card_steel_beetle card_magma_slug card_ember_bat card_forge_guardian card_rune_watcher card_silent_wraith golem_plate magma_core card_forge_golem card_pitman'.split()
monsters={p.stem:p.read_text(encoding='utf-8-sig') for p in (ROOT/'data/monsters').glob('*.tres')}
manifest=[]
for name in names:
 target=ROOT/'Sprites/items/placeholder'/f'{name}.png'
 backup=OUT/'mockup_backup'/target.name
 backup.parent.mkdir(exist_ok=True)
 if not backup.exists():shutil.copy2(target,backup)
 data=ROOT/('data/cards' if name.startswith('card_') else 'data/items')/(name+'.tres')
 txt=data.read_text(encoding='utf-8-sig')
 desc=re.search(r'description = "([^"]*)"',txt)
 sources=[m for m,t in monsters.items() if f'item_id = &"{name}"' in t]
 art=ROOT/'Sprites/card'/(name+'.webp')
 manifest.append(dict(id=name,description=desc[1] if desc else '',drops=sources,existing_card=str(art) if art.exists() else None))
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest,ensure_ascii=False))
print('CARD SIZE',Image.open(ROOT/'Sprites/card/card_wolf.webp').size)
