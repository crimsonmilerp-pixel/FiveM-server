"""Builds illenium-appearance shared/blacklist.lua from rules.py and the GTA clothing names list.
Usage: python3 build.py <v-clothingnames folder> <output blacklist.lua> <report.md>"""
import json, re, sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rules

SRC, OUT, REPORT = sys.argv[1], sys.argv[2], sys.argv[3]
GROUP_ORDER = ['festive', 'halloween', 'costume', 'racy']
SLOTS = [  # (blacklist section, key, file pattern)
    ('components', 'masks', 'masks_{g}.json'),
    ('components', 'lowerBody', '{g}_legs.json'),
    ('components', 'shoes', '{g}_shoes.json'),
    ('components', 'scarfAndChains', '{g}_accessories.json'),
    ('components', 'shirts', '{g}_undershirts.json'),
    ('components', 'jackets', '{g}_tops.json'),
    ('props', 'hats', 'props_{g}_hats.json'),
    ('props', 'glasses', 'props_{g}_glasses.json'),
    ('props', 'ear', 'props_{g}_ears.json'),
    ('props', 'watches', 'props_{g}_watches.json'),
    ('props', 'bracelets', 'props_{g}_bracelets.json'),
]
ALL_COMPONENTS = ['masks', 'upperBody', 'lowerBody', 'bags', 'shoes', 'scarfAndChains', 'shirts', 'bodyArmor', 'decals', 'jackets']
ALL_PROPS = ['hats', 'glasses', 'ear', 'watches', 'bracelets']

def compile_rules(extra):
    out = {}
    for grp in GROUP_ORDER:
        pats = list(rules.COMMON.get(grp, [])) + (list(extra.get(grp, [])) if extra else [])
        out[grp] = [re.compile(p, re.I) for p in pats]
    return out

def classify(name, compiled):
    for grp in GROUP_ORDER:
        for rx in compiled[grp]:
            if rx.search(name):
                return grp
    return None

result = {}            # (gender, key) -> list of (group, drawable, textures or None)
report = collections.defaultdict(list)
unlabeled = collections.defaultdict(list)
for g in ('male', 'female'):
    for section, key, pat in SLOTS:
        data = json.load(open(os.path.join(SRC, pat.format(g=g))))
        compiled = compile_rules(rules.MASKS if key == 'masks' else None)
        entries = []
        for dr, tex in sorted(data.items(), key=lambda kv: int(kv[0])):
            labeled, groups = {}, {}
            for t, v in tex.items():
                n = (v or {}).get('Localized') if isinstance(v, dict) else None
                if n and n not in ('NULL', 'NO_LABEL', 'None'):
                    labeled[int(t)] = n
                    grp = classify(n, compiled)
                    if grp: groups[int(t)] = grp
            if not labeled:
                if int(dr) != 0: unlabeled[(g, key)].append(int(dr))
                continue
            if not groups:
                continue
            if len(groups) == len(labeled):
                # every named color is out: hide the whole item (unnamed colors are variants of it)
                grp = collections.Counter(groups.values()).most_common(1)[0][0]
                entries.append((grp, int(dr), None))
                report[(g, key, grp)].append(f"{dr} {sorted(set(labeled.values()))[0]}")
            else:
                by = collections.defaultdict(list)
                for t, grp in groups.items(): by[grp].append(t)
                for grp, ts in by.items():
                    entries.append((grp, int(dr), sorted(ts)))
                    report[(g, key, grp)].append(f"{dr} (colors {','.join(map(str, sorted(ts)))}) {labeled[sorted(ts)[0]]}")
        result[(g, key)] = entries

def lua_list(xs): return '{ ' + ', '.join(map(str, xs)) + ' }'

lines = [
    '-- ============================================================',
    '-- [OUR CHANGE] Clothing blacklist (Pillar C: a grounded world). Generated, do not edit by hand:',
    '-- change docs/clothing-blacklist/rules.py and ask Claude to rebuild it. See docs/core-changes.md',
    '--',
    '-- Hidden items are grouped by an ACE permission. Anyone who has the permission sees that group again:',
    '--   clothing.festive    Christmas, Valentine\'s, Thanksgiving, New Year\'s (switch on in season)',
    '--   clothing.halloween  horror and monster costumes (switch on in October)',
    '--   clothing.costume    cartoon characters, mascots, sci-fi, glowing, apocalypse armor',
    '--   clothing.racy       lingerie',
    '-- Switch a group on for everyone in permissions.cfg (or live in the txAdmin console):',
    '--   add_ace builtin.everyone clothing.festive allow',
    '-- ============================================================',
    'Config.Blacklist = {',
]
for g in ('male', 'female'):
    lines.append(f'    {g} = {{')
    lines.append('        hair = {},')
    for section, keys in (('components', ALL_COMPONENTS), ('props', ALL_PROPS)):
        lines.append(f'        {section} = {{')
        for key in keys:
            entries = result.get((g, key), [])
            if not entries:
                lines.append(f'            {key} = {{}},'); continue
            lines.append(f'            {key} = {{')
            for grp in GROUP_ORDER:
                whole = sorted(d for gg, d, t in entries if gg == grp and t is None)
                if whole:
                    lines.append(f"                {{ aces = {{ 'clothing.{grp}' }}, drawables = {lua_list(whole)} }},")
                for gg, d, t in sorted((e for e in entries if e[0] == grp and e[2] is not None), key=lambda e: e[1]):
                    lines.append(f"                {{ aces = {{ 'clothing.{grp}' }}, drawables = {{ {d} }}, textures = {lua_list(t)} }},")
            lines.append('            },')
        lines.append('        },')
    lines.append('    },')
lines.append('}')
open(OUT, 'w').write('\n'.join(lines) + '\n')

# Report for the docs
r = ['# Clothing blacklist report', '', 'Generated by `build.py`. Item numbers match the slider numbers in the clothing menu.', '']
for g in ('male', 'female'):
    r.append(f'## {g.title()}'); r.append('')
    for section, key, pat in SLOTS:
        for grp in GROUP_ORDER:
            items = report.get((g, key, grp))
            if items:
                r.append(f'**{key} — {grp}** ({len(items)}): ' + '; '.join(items)); r.append('')
r.append('## Items with no name (not checked)'); r.append('')
r.append('These have no in-game name, so the rules could not check them. If you spot a costume among them in the clothing menu, note the number.'); r.append('')
for (g, key), ds in sorted(unlabeled.items()):
    r.append(f'- {g} {key}: ' + ', '.join(map(str, ds)))
open(REPORT, 'w').write('\n'.join(r) + '\n')

tot = collections.Counter()
for (g, key), es in result.items():
    for grp, d, t in es: tot[(g, grp, 'whole' if t is None else 'colors')] += 1
for k in sorted(tot): print(k, tot[k])
print('unlabeled', sum(len(v) for v in unlabeled.values()))
