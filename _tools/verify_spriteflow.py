"""Verify imported bytes and that only the intended visual data changed."""
from pathlib import Path
from PIL import Image
import hashlib, json, sys, re

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'output/spriteflow'
VISUAL = {'fit_fixed_anchor_enabled','fit_fixed_anchor','fit_uniform_scale','fit_animation_scales'}
report = {}
selected = sys.argv[1:] or ['thorn_hound','vanir_sentinel','thorn_matriarch','war_wraith']
for mid in selected:
    manifest = json.loads((WORK/f'{mid}_manifest.json').read_text())
    data = Path(f'data/monsters/{mid}.tres')
    allowed = VISUAL | ({
        'projectile_texture','ranged_attack','ranged_attack_range','projectile_speed',
        'projectile_height','projectile_hit_size','projectile_range','projectile_fire_effect',
        'projectile_aim_at_player','projectile_hand_positions','attack_hit_frames',
        'attack_follow_anim','attack_windup','attack_duration'
    } if mid == 'gullveig_ember' else set())
    def core(path):
        text = path.read_text(encoding='utf-8-sig')
        for key in allowed:
            text = re.sub(r'^'+key+r' = .*?(?=^[A-Za-z_]\w* = |^\[|\Z)', '', text, flags=re.M|re.S)
        # Godot may attach resource UIDs and expand typed dictionaries on save.
        text = re.sub(r' uid="[^"]+"', '', text)
        return [line for line in text.splitlines() if line.strip() and 'id="5_fireball"' not in line]
    assert core(ROOT/data) == core(WORK/'before'/data), mid+' gameplay data changed'
    seen, edge = set(), []
    for clip in manifest['animations'].values():
        for f in clip['frames']:
            key = (clip['source'],f)
            if key in seen: continue
            seen.add(key)
            src = WORK/'downloads'/key[0]/f'frame_{f:02}.png'
            dst = ROOT/'Sprites/monsters/spriteflow'/mid/key[0]/src.name
            assert hashlib.sha256(src.read_bytes()).digest() == hashlib.sha256(dst.read_bytes()).digest()
            with Image.open(dst) as image:
                alpha = image.getchannel('A')
                assert alpha.getextrema()[0] == 0
                box = alpha.point(lambda a:255 if a>20 else 0).getbbox()
                if not box:
                    assert mid == 'mist_sprite' and clip['source']=='mist_sprite_attack_hit_die' and f in (25,26)
                    continue
                if box[0]==0 or box[1]==0 or box[2]==image.width or box[3]==image.height:
                    edge.append({'source':key[0],'frame':f,'bbox':box})
    audit_path = WORK/('fire_update/runtime/audit.json' if mid=='gullveig_ember' else f'runtime/{mid}/audit.json')
    audit = json.loads(audit_path.read_text())
    assert not audit['failures'], mid+' runtime audit failed'
    assert len(seen) == manifest['unique_frames']
    report[mid] = {'verified_unchanged_pngs':len(seen),'unrelated_gameplay_fields_unchanged':True,'source_edge_contact':edge,'runtime_checks':audit['checks'],'runtime_failures':0}
(WORK/('fire_update/validation.json' if sys.argv[1:] else 'validation.json')).write_text(json.dumps(report,indent=2))
print('VERIFIED',sum(r['verified_unchanged_pngs'] for r in report.values()),'original PNGs;',sum(r['runtime_checks'] for r in report.values()),'runtime checks; unrelated gameplay fields unchanged.')
