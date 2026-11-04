"""Contact sheets of every texture, grouped by ped + slot. Usage: preview.py <extracted root>... <outdir>"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw, ImageFont
import ytd
from scan import scan, COMPS, PROPS

def thumb(path, size):
    try:
        t = ytd.textures(open(path, 'rb').read())[0]
        im = ytd.to_image(t).convert('RGB')
    except Exception as e:
        im = Image.new('RGB', (size, size), (90, 0, 0))
    im.thumbnail((size, size))
    return im

def sheets(groups, outdir, size=160, cols=8, per_sheet=48, only=None):
    os.makedirs(outdir, exist_ok=True)
    font = ImageFont.load_default()
    by = {}
    for k, g in groups.items():
        if not g['model'] or not g['tex']: continue
        if only and not only(g): continue
        ped, prop, coll, slot, idx = k
        name = ('p_' + PROPS[slot]) if prop else COMPS[slot]
        for l in sorted(g['tex']):
            by.setdefault((ped[3], name), []).append(('%s %s %03d%s' % (coll[:14], name, idx, l), g['tex'][l]['path']))
    written = []
    for (sex, name), cells in sorted(by.items()):
        for s in range(0, len(cells), per_sheet):
            chunk = cells[s:s + per_sheet]
            rows = (len(chunk) + cols - 1) // cols
            sheet = Image.new('RGB', (cols * size, rows * (size + 14)), (255, 255, 255))
            d = ImageDraw.Draw(sheet)
            for i, (label, path) in enumerate(chunk):
                x, y = (i % cols) * size, (i // cols) * (size + 14)
                sheet.paste(thumb(path, size - 4), (x + 2, y + 2))
                d.text((x + 2, y + size), label, fill=(0, 0, 0), font=font)
            fn = os.path.join(outdir, '%s_%s_%02d.png' % (sex, name, s // per_sheet))
            sheet.save(fn); written.append((fn, len(chunk)))
    return written

if __name__ == '__main__':
    groups, _ = scan(sys.argv[1:-1])
    for fn, n in sheets(groups, sys.argv[-1]): print(fn, n)
