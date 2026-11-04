"""Scans extracted EUP folders and groups files into drawables."""
import os, re, json, sys
from collections import defaultdict

COMPS = ['head', 'berd', 'hair', 'uppr', 'lowr', 'hand', 'feet', 'teef', 'accs', 'task', 'decl', 'jbib']
PROPS = ['head', 'eyes', 'ears', 'mouth', 'lhand', 'rhand', 'lwrist', 'rwrist', 'hip', 'lfoot', 'rfoot']
RACES = ['uni', 'whi', 'bla', 'chi', 'lat', 'ara', 'bal', 'jam', 'kor', 'ita', 'pak']
PEDS = ['mp_m_freemode_01', 'mp_f_freemode_01']

c_model = re.compile(r'^(%s)_(\d{3})_([ur])(_\d)?\.ydd$' % '|'.join(COMPS))
c_tex = re.compile(r'^(%s)_diff_(\d{3})_([a-z])_(%s)\.ytd$' % ('|'.join(COMPS), '|'.join(RACES)))
c_cloth = re.compile(r'^(%s)_(\d{3})_([ur])\.yld$' % '|'.join(COMPS))
p_model = re.compile(r'^p_(%s)_(\d{3})(_\d)?\.ydd$' % '|'.join(PROPS))
p_tex = re.compile(r'^p_(%s)_diff_(\d{3})_([a-z])\.ytd$' % '|'.join(PROPS))

def split_folder(folder):
    f = folder.lower()
    for ped in PEDS:
        if f.startswith(ped):
            rest = f[len(ped):]
            prop = rest == '_p' or rest.startswith('_p_')
            if prop:
                rest = rest[2:]
            return ped, prop, rest.lstrip('_') or 'base'
    return None, None, None

def scan(roots):
    groups = {}
    unknown = []
    def g(key):
        if key not in groups:
            groups[key] = dict(key=key, model=None, suffix=None, alts={}, tex={}, cloth=None)
        return groups[key]
    for root in roots:
        for folder in sorted(os.listdir(root)):
            fp = os.path.join(root, folder)
            if not os.path.isdir(fp):
                unknown.append(fp); continue
            ped, prop, coll = split_folder(folder)
            if not ped:
                unknown.append(fp); continue
            for name in sorted(os.listdir(fp)):
                path = os.path.join(fp, name)
                n = name.lower()
                size = os.path.getsize(path)
                if not prop:
                    m = c_model.match(n)
                    if m:
                        slot, idx, suf, alt = m.group(1), int(m.group(2)), m.group(3), m.group(4)
                        d = g((ped, False, coll, COMPS.index(slot), idx))
                        if alt: d['alts'][alt] = path
                        else: d['model'] = path; d['suffix'] = suf
                        continue
                    m = c_tex.match(n)
                    if m:
                        d = g((ped, False, coll, COMPS.index(m.group(1)), int(m.group(2))))
                        d['tex'][m.group(3)] = dict(path=path, race=m.group(4), size=size)
                        continue
                    m = c_cloth.match(n)
                    if m:
                        g((ped, False, coll, COMPS.index(m.group(1)), int(m.group(2))))['cloth'] = path
                        continue
                else:
                    m = p_model.match(n)
                    if m:
                        d = g((ped, True, coll, PROPS.index(m.group(1)), int(m.group(2))))
                        if m.group(3): d['alts'][m.group(3)] = path
                        else: d['model'] = path
                        continue
                    m = p_tex.match(n)
                    if m:
                        d = g((ped, True, coll, PROPS.index(m.group(1)), int(m.group(2))))
                        d['tex'][m.group(3)] = dict(path=path, race=None, size=size)
                        continue
                unknown.append(path)
    return groups, unknown

if __name__ == '__main__':
    groups, unknown = scan(sys.argv[1:])
    full = [v for v in groups.values() if v['model']]
    texonly = [v for v in groups.values() if not v['model']]
    print('drawables with model:', len(full), ' texture-only:', len(texonly), ' unknown files:', len(unknown))
    for u in unknown[:20]: print('  ?', u)
    from collections import Counter
    c = Counter((k[0][3], 'prop' if k[1] else 'comp', (PROPS if k[1] else COMPS)[k[3]]) for k in (v['key'] for v in full))
    for k in sorted(c): print(' ', k, c[k])
    print('textures in model groups:', sum(len(v['tex']) for v in full), ' alts:', sum(len(v['alts']) for v in full), ' cloth:', sum(1 for v in full if v['cloth']))
