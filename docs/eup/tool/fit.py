"""fit.py: how well an overlay piece sits on a base piece (signed distance of overlay vertices to the base surface)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from scipy.spatial import cKDTree
import ydd
from scan import scan, COMPS, PROPS
_groups = None; _idx = {}
def model(ped, slot, n):
    global _groups
    if _groups is None:
        _groups, _ = scan(['raw/comps', 'raw/props'])
        sel = json.load(open('selection_v1.json'))
        for p, items in sel.items():
            cnt = {}
            for it in items:
                k = tuple(it['key']); name = ('p_' + PROPS[k[3]]) if k[1] else COMPS[k[3]]
                c = cnt.get(name, 0); cnt[name] = c + 1; _idx[(p, name, c)] = _groups[k]['model']
    return _idx[(ped, slot, n)]
_cache = {}
def pts(ped, slot, n):
    key = (ped, slot, n)
    if key not in _cache:
        v = ydd.positions(model(ped, slot, n), normals=True)
        _cache[key] = (np.array([a for a, b in v]), np.array([b for a, b in v]))
    return _cache[key]
def fit(ped, base, over):
    bp, bn = pts(ped, *base); op, _ = pts(ped, *over)
    d, i = cKDTree(bp).query(op)
    signed = np.einsum('ij,ij->i', op - bp[i], bn[i])
    return dict(n=len(op), dist_med=float(np.median(d)), dist_max=float(d.max()),
                inside=float((signed < -0.002).mean()), floating=float((d > 0.03).mean()))
if __name__ == '__main__':
    ped = sys.argv[1]
    base = (sys.argv[2], int(sys.argv[3]))
    for o in sys.argv[4:]:
        s, n = o.split(':')
        r = fit(ped, base, (s, int(n)))
        print('%s %s on %s %d: med %.3f max %.3f  inside %.0f%%  floating %.0f%%' % (s, n, base[0], base[1], r['dist_med'], r['dist_max'], r['inside'] * 100, r['floating'] * 100))
