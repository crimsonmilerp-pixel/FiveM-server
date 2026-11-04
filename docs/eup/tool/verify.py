import sys, os, re, struct, collections
sys.path.insert(0, os.path.dirname(__file__))
import ymt
from scan import COMPS, PROPS
root = sys.argv[1]; dlc = sys.argv[2]
files = {}
for dp, dn, fn in os.walk(os.path.join(root, 'stream')):
    for f in fn: files[f] = os.path.join(dp, f)
problems = []
vers = collections.Counter()
for f, p in files.items():
    if f.endswith('.ymt'): continue
    h = open(p, 'rb').read(16)
    if h[:4] != b'RSC7': problems.append('not RSC7: ' + f)
    vers[(f.rsplit('.', 1)[1], struct.unpack('<i', h[4:8])[0])] += 1
print('resource versions:', dict(vers))
for ped in ['mp_m_freemode_01', 'mp_f_freemode_01']:
    d = ymt.dump_variation(open(files['%s_%s.ymt' % (ped, dlc)], 'rb').read())
    assert d['name'] == dlc and d['dlcName'] == ymt.H(dlc)
    ci = 0; n_inf = 0
    for comp in range(12):
        if d['avail'][comp] == 255:
            if any(re.match(r'%s_%s\^%s_\d{3}_' % (ped, dlc, COMPS[comp]), f) for f in files): problems.append('files but no ymt comp %s' % COMPS[comp])
            continue
        c = d['comps'][d['avail'][comp]]
        for di, dr in enumerate(c['draws']):
            m = [f for f in files if re.match(r'%s_%s\^%s_%03d_[ur]\.ydd$' % (ped, dlc, COMPS[comp], di), f)]
            if len(m) != 1: problems.append('model %s %s %d: %s' % (ped, COMPS[comp], di, m))
            suf = m[0][-5] if m else '?'
            tx = sorted(f for f in files if re.match(r'%s_%s\^%s_diff_%03d_[a-z]_[a-z]{3}\.ytd$' % (ped, dlc, COMPS[comp], di), f))
            if len(tx) != len(dr['tex']): problems.append('tex count %s %s %d: ymt %d files %d' % (ped, COMPS[comp], di, len(dr['tex']), len(tx)))
            letters = [t.split('_diff_')[1][4] for t in tx]
            if letters != list('abcdefghijklmnopqrstuvwxyz'[:len(tx)]): problems.append('letters %s %s %d %s' % (ped, COMPS[comp], di, letters))
            races = {t[-7:-4] for t in tx}
            want = 1 if suf == 'r' else 0
            if any(t[0] != want for t in dr['tex']) or (suf == 'u' and races != {'uni'}) or (suf == 'r' and 'uni' in races):
                problems.append('race %s %s %d %s %s' % (ped, COMPS[comp], di, suf, races))
            if c['numAvailTex'] != sum(len(x['tex']) for x in c['draws']) & 0xFF: problems.append('numAvailTex')
        n_inf += len(c['draws'])
    if len(d['compInfos']) != n_inf: problems.append('compInfos %d vs %d' % (len(d['compInfos']), n_inf))
    for info in d['compInfos']:
        comp, di = info[-2], info[-1]
    pk = collections.Counter()
    for p in d['props']:
        a = p['anchor']; pi = p['propId']; pk[a] += 1
        m = [f for f in files if f == '%s_p_%s^p_%s_%03d.ydd' % (ped, dlc, PROPS[a], pi)]
        tx = [f for f in files if re.match(r'%s_p_%s\^p_%s_diff_%03d_[a-z]\.ytd$' % (ped, dlc, PROPS[a], pi), f)]
        if len(m) != 1 or len(tx) != len(p['tex']): problems.append('prop %s %s %d' % (ped, PROPS[a], pi))
    for a, counts in d['anchors']:
        if len(counts) != pk[a]: problems.append('anchor count')
    print(ped, 'components:', {COMPS[i]: len(d['comps'][d['avail'][i]]['draws']) for i in range(12) if d['avail'][i] != 255},
          'props:', {PROPS[a]: len(c) for a, c in d['anchors']})
total_ymt_files = sum(1 for f in files if not f.endswith('.ymt'))
print('files:', len(files), 'problems:', len(problems))
for p in problems[:30]: print('  ', p)
