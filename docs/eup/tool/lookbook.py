import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw, ImageFont
import render, uniforms
from scan import scan, COMPS, PROPS
sel = json.load(open('selection_v1.json'))
groups, _ = scan(['raw/comps', 'raw/props'])
PED = {'Male': 'mp_m_freemode_01', 'Female': 'mp_f_freemode_01'}
_index = {}
def piece(ped, slot, n, t):
    if not _index:
        for p, items in sel.items():
            cnt = {}
            for it in items:
                k = tuple(it['key']); name = ('p_' + PROPS[k[3]]) if k[1] else COMPS[k[3]]
                c = cnt.get(name, 0); cnt[name] = c + 1; _index[(p, name, c)] = (k, it['tex'])
    k, letters = _index[(ped, slot, n)]
    return groups[k]['model'], groups[k]['tex'][letters[t]]['path']
def parts_of(gender, o):
    ped = PED[gender]; parts = []
    for key, pc in o['data'].items():
        if pc is None or pc[0] == 'base': continue
        parts.append(piece(ped, pc[0], pc[1], pc[2]))
    return parts
if __name__ == '__main__':
    gender = sys.argv[1]; out = sys.argv[2]; views = sys.argv[3].split(',') if len(sys.argv) > 3 else ['front']
    outfits = uniforms.build(gender)
    W, H = 300, 560
    cells = []
    for o in outfits:
        ps = parts_of(gender, o)
        ims = [render.render(ps, size=(W, H), view=v, zrange=(-1.05, 0.95)) for v in views]
        cells.append((o['name'], ims))
    cols = 5 if len(views) == 1 else 2
    cw = W * len(views); rows = (len(cells) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * cw, rows * (H + 22)), 'white'); d = ImageDraw.Draw(sheet)
    for i, (name, ims) in enumerate(cells):
        x, y = (i % cols) * cw, (i // cols) * (H + 22)
        for j, im in enumerate(ims): sheet.paste(im, (x + j * W, y))
        d.text((x + 6, y + H + 4), name, fill=(0, 0, 0))
    sheet.save(out); print(out, sheet.size, len(cells))
