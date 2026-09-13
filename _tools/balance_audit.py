from pathlib import Path
import re, json
ROOT = Path(__file__).resolve().parents[1]
def read(p):
    text = p.read_text(encoding='utf-8-sig')
    main = text.split('[resource]')[-1]
    values = dict(re.findall(r'^(\w+) = (.+)$', main, re.M))
    def val(v):
        try: return json.loads(v)
        except: return v.removeprefix('&').strip('"')
    return {k:val(v) for k,v in values.items()}
if __name__ == '__main__':
    result = {kind:{p.stem:read(p) for p in (ROOT/'data'/kind).glob('*.tres')} for kind in ['items','monsters','skills']}
    out = ROOT/'output/balance'
    out.mkdir(parents=True, exist_ok=True)
    snap = out/'before.json'
    if not snap.exists(): snap.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    for id,d in result['monsters'].items():
        print('MON', id, *[d.get(k,0) for k in ['level','max_hp','def','element','exp_reward','zeny_min','zeny_max','is_boss']])
    for id,d in result['items'].items():
        if d.get('type') in [1,2]:
            print('EQ', id, *[d.get(k,0) for k in ['required_level','atk','def','buy_price','sell_price']])
