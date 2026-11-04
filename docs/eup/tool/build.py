"""Builds the FiveM add-on clothing resource from scanned EUP groups.
selection: list of dict(key=group key tuple, tex=[letters in order]) per ped; order = new drawable order."""
import os, shutil, json, sys
sys.path.insert(0, os.path.dirname(__file__))
import ymt
from scan import COMPS, PROPS

def ped_letter(ped): return 'm' if ped.startswith('mp_m') else 'f'
LETTERS = 'abcdefghijklmnopqrstuvwxyz'

def build(groups, selection, dlc, out, copy=True):
    """selection: {ped: [ {key, tex:[letters]} ...]} ; returns mapping list."""
    stream = os.path.join(out, 'stream')
    os.makedirs(stream, exist_ok=True)
    mapping = []
    metas = []
    for ped, items in selection.items():
        g = 'male' if ped_letter(ped) == 'm' else 'female'
        comps = {}; props = {}
        for it in items:
            grp = groups[tuple(it['key'])]
            _, is_prop, coll, slot, idx = grp['key']
            letters = it.get('tex') or sorted(grp['tex'])
            target = props if is_prop else comps
            lst = target.setdefault(slot, [])
            new = len(lst)
            if new > 255: raise ValueError('too many drawables in %s %s' % (ped, slot))
            if is_prop:
                base = '%s_p_%s^p_%s_%03d' % (ped, dlc, PROPS[slot], new)
                files = [(grp['model'], base + '.ydd')]
                for i, l in enumerate(letters):
                    files.append((grp['tex'][l]['path'], '%s_p_%s^p_%s_diff_%03d_%s.ytd' % (ped, dlc, PROPS[slot], new, LETTERS[i])))
                lst.append(dict(textures=len(letters)))
                sub = os.path.join(stream, g, 'p_' + PROPS[slot])
            else:
                suf = grp['suffix']
                races = {grp['tex'][l]['race'] for l in letters}
                assert len(races) == 1, (grp['key'], races)
                race = races.pop()
                base = '%s_%s^%s_%03d_%s' % (ped, dlc, COMPS[slot], new, suf)
                files = [(grp['model'], base + '.ydd')]
                # First-person alternate models (_1) are left out on purpose: the normal model is used in first person.
                if grp['cloth']:
                    files.append((grp['cloth'], base + '.yld'))
                for i, l in enumerate(letters):
                    files.append((grp['tex'][l]['path'], '%s_%s^%s_diff_%03d_%s_%s.ytd' % (ped, dlc, COMPS[slot], new, LETTERS[i], race)))
                skin = suf == 'r'
                lst.append(dict(textures=len(letters), texId=1 if skin else 0, propMask=17 if skin else 1,
                                alternatives=0, cloth=bool(grp['cloth'])))
                sub = os.path.join(stream, g, COMPS[slot])
            os.makedirs(sub, exist_ok=True)
            for src, dst in files:
                if copy: shutil.copyfile(src, os.path.join(sub, dst))
            mapping.append(dict(ped=ped, prop=is_prop, slot=(PROPS if is_prop else COMPS)[slot], slotIndex=slot, new=new,
                                source=dict(collection=coll, index=idx), letters=letters))
        data = ymt.build_variation(dlc, comps, props)
        open(os.path.join(stream, '%s_%s.ymt' % (ped, dlc)), 'wb').write(data)
        meta = '%s_%s.meta' % (ped, dlc)
        metas.append(meta)
        ch = 'SCR_CHAR_MULTIPLAYER' if ped_letter(ped) == 'm' else 'SCR_CHAR_MULTIPLAYER_F'
        open(os.path.join(out, meta), 'w', newline='\n').write(
            '<?xml version="1.0" encoding="UTF-8"?>\n<ShopPedApparel>\n'
            '  <pedName>%s</pedName>\n  <dlcName>%s</dlcName>\n  <fullDlcName>%s_%s</fullDlcName>\n'
            '  <eCharacter>%s</eCharacter>\n  <creatureMetaData>mp_creaturemetadata_%s_%s</creatureMetaData>\n'
            '  <pedOutfits />\n  <pedComponents />\n  <pedProps />\n</ShopPedApparel>\n'
            % (ped, dlc, ped, dlc, ch, ped_letter(ped), dlc))
    return mapping, metas

if __name__ == '__main__':
    from scan import scan
    groups, unknown = scan([sys.argv[1]])
    sel = {}
    for k, v in sorted(groups.items()):
        if v['model'] and v['tex']:
            sel.setdefault(k[0], []).append(dict(key=k))
    mapping, metas = build(groups, sel, 'rp_eup', sys.argv[2])
    print(len(mapping), metas)
