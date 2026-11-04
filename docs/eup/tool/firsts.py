"""firsts.py <sel> <ped> <slot> <out.png> [size] [indices comma] [texidx] : first (or given) texture of each piece."""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw
from scan import scan, COMPS, PROPS
import ytd
sel = json.load(open(sys.argv[1])); ped, slot, out = sys.argv[2], sys.argv[3], sys.argv[4]
size = int(sys.argv[5]) if len(sys.argv) > 5 else 200
only = [int(x) for x in sys.argv[6].split(',')] if len(sys.argv) > 6 and sys.argv[6] != '-' else None
ti = int(sys.argv[7]) if len(sys.argv) > 7 else 0
groups, _ = scan(['raw/comps', 'raw/props'])
cells = []; n = -1
for it in sel[ped]:
    k = tuple(it['key']); name = ('p_' + PROPS[k[3]]) if k[1] else COMPS[k[3]]
    if name != slot: continue
    n += 1
    if only and n not in only: continue
    l = it['tex'][min(ti, len(it['tex']) - 1)]
    im = ytd.to_image(ytd.textures(open(groups[k]['tex'][l]['path'], 'rb').read())[0]).convert('RGB'); im.thumbnail((size, size))
    cells.append(('%s #%d (%d tex) %s' % (slot, n, len(it['tex']), k[2][5:17]), im))
cols = 6; rows = (len(cells) + cols - 1) // cols
sheet = Image.new('RGB', (cols * size, rows * (size + 14)), 'white'); d = ImageDraw.Draw(sheet)
for i, (lab, im) in enumerate(cells):
    x, y = (i % cols) * size, (i // cols) * (size + 14); sheet.paste(im, (x, y)); d.text((x + 2, y + size), lab, fill=(0, 0, 0))
sheet.save(out); print(out, sheet.size)
