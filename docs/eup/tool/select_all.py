"""Builds the append-only selection manifest: every EUP drawable that ships its own model,
minus tiny placeholder textures (< 2 KB, 64x64 blanks)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from scan import scan, COMPS, PROPS
TINY = 2000
def make(groups):
    sel = {}
    for k in sorted(groups, key=lambda k: (k[0], k[1], k[3], k[2], k[4])):
        g = groups[k]
        if not g['model']: continue
        letters = [l for l in sorted(g['tex']) if g['tex'][l]['size'] >= TINY]
        if not letters: continue
        sel.setdefault(k[0], []).append(dict(key=list(k), tex=letters))
    return sel
if __name__ == '__main__':
    groups, _ = scan(sys.argv[1:-1])
    sel = make(groups)
    json.dump(sel, open(sys.argv[-1], 'w'), indent=0)
    for ped, items in sel.items():
        print(ped, len(items), 'drawables', sum(len(i['tex']) for i in items), 'textures')
