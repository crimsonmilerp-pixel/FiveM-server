"""Writes the illenium-appearance Config.Outfits["police"] block from uniforms.py."""
import sys, os, re
sys.path.insert(0, os.path.dirname(__file__))
import uniforms
BADGE = {0: 'Police Officer', 1: 'Sergeant', 2: 'Lieutenant', 3: 'Captain', 8: 'Chief of Police'}
def describe(key, pc, gender):
    kind, n, t = pc
    if key == 'torso2':
        return {1: None}.get(0) or {('jbib', 40): 'LSPD shirt, short sleeve', ('jbib', 41): 'LSPD shirt, long sleeve', ('jbib', 42): 'LSPD shirt, closed collar and tie',
                ('jbib', 36): 'LSPD shirt, short sleeve', ('jbib', 37): 'LSPD shirt, long sleeve', ('jbib', 39): 'LSPD shirt, closed collar and tie'}[(kind, n)]
    if key == 'pants': return 'Navy uniform trousers'
    if key == 't-shirt': return 'Duty belt (holster, taser, cuffs, keys)'
    if key == 'vest': return 'Radio on the belt, cord up to the shoulder mic'
    if key == 'bag': return 'Badge "%s" and name tag' % BADGE[t]
    if key == 'decals':
        if kind == 'base': return 'No insignia'
        if n in (6, 16, 5, 15): return {0: 'Sleeve stripes: two', 1: 'Sleeve stripes: two and a star', 2: 'Sleeve stripes: three (Sergeant)'}[t]
        if n in (13, 12) and t in (6, 7): return {6: 'Collar: one gold bar', 7: 'Collar: two gold bars'}[t]
        return 'Collar: four gold stars'
    if key == 'arms': return 'Arms, bare hands'
    if key == 'shoes': return 'Black lace-up boots'
    if key == 'mask': return 'No mask'
    if key == 'accessory': return 'No neck accessory'
    if key == 'hat': return 'LSPD service cap' if kind != 'base' else 'No hat'
    return ''
ORDER = ['torso2', 'arms', 't-shirt', 'vest', 'pants', 'shoes', 'bag', 'decals', 'accessory', 'mask', 'hat']
def piece_lua(key, pc):
    kind, n, t = pc
    if kind == 'base':
        return '{item = %d, texture = %d}' % (n, t)
    return '{collection = "rp_eup", item = %d, texture = %d}' % (n, t)
def block(swat_male, swat_female):
    L = []
    L.append('    ["police"] = { -- [OUR CHANGE] Nov 4: LSPD rank uniforms from the rp_eup pack (resources/[assets]/rp_eup).')
    L.append('        -- Generated: change docs/eup/tool/uniforms.py and ask Claude to rebuild. Pieces with collection = "rp_eup" use the')
    L.append('        -- piece number inside the pack (they never move); the others are normal game numbers. Pictures: docs/eup/lookbook/')
    L.append('        -- Rank shows on the badge, the sleeves (Officer II and up) and the collar (Lieutenant and up). See docs/core-changes.md')
    for gender, swat in (('Male', swat_male), ('Female', swat_female)):
        L.append('        ["%s"] = {' % gender)
        for o in uniforms.build(gender):
            L.append('            {')
            L.append('                name = "%s",' % o['name'])
            L.append('                outfitData = {')
            keys = [k for k in ORDER if k in o['data']]
            for i, k in enumerate(keys):
                comma = ',' if i < len(keys) - 1 else ''
                L.append('                    ["%s"] = %s%s -- %s' % (k, piece_lua(k, o['data'][k]), comma, describe(k, o['data'][k], gender)))
            L.append('                },')
            L.append('                grades = {%s},' % ', '.join(str(g) for g in o['grades']))
            L.append('            },')
        L.extend(swat)
        L.append('        },')
    L[-1] = '        }'
    L.append('    }')
    return '\n'.join(L)
if __name__ == '__main__':
    src, out = sys.argv[1], sys.argv[2]
    s = open(src, 'rb').read().decode().replace('\r\n', '\n')
    a = s.index('Config.Outfits = {')
    p = s.index('    ["police"] = {', a)
    i = s.index('{', p); depth = 0
    for j in range(i, len(s)):
        if s[j] == '{': depth += 1
        elif s[j] == '}':
            depth -= 1
            if depth == 0: end = j; break
    old = s[p:end + 1]
    swats = []
    for g in ('["Male"]', '["Female"]'):
        gi = old.index(g)
        sw = old.index('name = "SWAT"', gi)
        st = old.rindex('\n            {', 0, sw) + 1
        en = old.index('\n            }', sw) + len('\n            }')
        lines = old[st:en].split('\n')
        lines = [l.replace('name = "SWAT",', 'name = "SWAT: Tactical Gear", -- [OUR CHANGE] Nov 4: only for officers with the SWAT certification\n                cert = "swat",') for l in lines]
        txt = '\n'.join(lines)
        swats.append(txt.split('\n'))
    new = block(swats[0], swats[1])
    s = s[:p] + new + s[end + 1:]
    open(out, 'wb').write(s.replace('\n', '\r\n').encode())
    print('outfits written; old block', old.count('name ='), 'names; new', new.count('name ='))
