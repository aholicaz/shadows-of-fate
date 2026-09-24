import json,re,sys
SPEC=re.compile(r"%[-+ 0#]*\d*(?:\.\d+)?[sdifxXc%]")
TAG=re.compile(r"\[/?[a-z_]+(?:=[^\]]*)?\]")
def check(i):
    src=json.load(open(f"chunk{i}.json")); out=json.load(open(f"out/chunk{i}.json"))
    bad=0
    for t in src:
        s=t["s"]
        if s not in out: print("MISSING",repr(s[:60])); bad+=1; continue
        e=out[s]
        if SPEC.findall(s)!=SPEC.findall(e): print("SPEC",repr(s[:60]),"|",repr(e[:60])); bad+=1
        if TAG.findall(s)!=TAG.findall(e): print("TAG",repr(s[:60]),"|",repr(e[:60])); bad+=1
        if s.count("\n")!=e.count("\n"): print("NL",repr(s[:60])); bad+=1
        if re.search(r"[฀-๿]",e): print("THAI LEFT",repr(e[:60])); bad+=1
    print(f"chunk{i}: {len(src)} strings, {bad} problems")
check(int(sys.argv[1]))
