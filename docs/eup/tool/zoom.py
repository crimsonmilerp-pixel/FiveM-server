"""zoom.py <sel.json> <ped> <slot> <newIdx> <out.png> [crop x0,y0,x1,y1 as fractions] [size]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw
from scan import scan, COMPS, PROPS
import ytd
sel = json.load(open(sys.argv[1])); ped, slot, idx, out = sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5]
crop = [float(x) for x in sys.argv[6].split(',')] if len(sys.argv) > 6 and sys.argv[6] != '-' else None
size = int(sys.argv[7]) if len(sys.argv) > 7 else 300
groups, _ = scan(['raw/comps', 'raw/props'])
n = -1
for it in sel[ped]:
    k = tuple(it['key']); name = ('p_' + PROPS[k[3]]) if k[1] else COMPS[k[3]]
    if name != slot: continue
    n += 1
    if n == idx: break
g = groups[k]; paths = [g['tex'][l]['path'] for l in it['tex']]
cols = 4 if crop is None else 6
ims = []
for p in paths:
    im = ytd.to_image(ytd.textures(open(p, 'rb').read())[0]).convert('RGB')
    if crop: im = im.crop((int(crop[0]*im.width), int(crop[1]*im.height), int(crop[2]*im.width), int(crop[3]*im.height)))
    im.thumbnail((size, size)); ims.append(im)
w = max(i.width for i in ims); h = max(i.height for i in ims)
rows = (len(ims) + cols - 1) // cols
sheet = Image.new('RGB', (cols * w, rows * (h + 14)), (255, 255, 255)); d = ImageDraw.Draw(sheet)
for i, im in enumerate(ims):
    x, y = (i % cols) * w, (i // cols) * (h + 14); sheet.paste(im, (x, y)); d.text((x + 2, y + h), '%s #%d t%d (%s)' % (slot, idx, i, k[2][:12]), fill=(0, 0, 0))
sheet.save(out); print(out, sheet.size, k)
