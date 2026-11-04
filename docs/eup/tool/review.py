"""Review sheets: one block per new drawable, all its textures, labelled with the NEW local index."""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw, ImageFont
from scan import scan, COMPS, PROPS
from preview import thumb

def run(roots, selpath, outdir, size=104, cols=12, maxh=1500, slots=None, peds=None):
    groups, _ = scan(roots)
    sel = json.load(open(selpath))
    os.makedirs(outdir, exist_ok=True)
    font = ImageFont.load_default()
    out = []
    for ped, items in sel.items():
        if peds and ped not in peds: continue
        counters = {}
        rows_by_slot = {}
        for it in items:
            k = tuple(it['key']); g = groups[k]
            name = ('p_' + PROPS[k[3]]) if k[1] else COMPS[k[3]]
            new = counters.get(name, 0); counters[name] = new + 1
            rows_by_slot.setdefault(name, []).append((new, k, [g['tex'][l]['path'] for l in it['tex']]))
        for name, rows in rows_by_slot.items():
            if slots and name not in slots: continue
            blocks = []
            for new, k, paths in rows:
                lines = (len(paths) + cols - 2) // (cols - 1)
                blocks.append((new, k, paths, lines))
            page, h, pn = [], 0, 0
            def flush(page, pn):
                H = sum(b[3] for b in page) * (size + 12)
                sheet = Image.new('RGB', (cols * size, H), (255, 255, 255))
                d = ImageDraw.Draw(sheet); y = 0
                for new, k, paths, lines in page:
                    d.rectangle([0, y, size - 2, y + size], fill=(30, 30, 90))
                    d.text((6, y + 6), '%s' % name, fill=(255, 255, 255), font=font)
                    d.text((6, y + 26), '#%d' % new, fill=(255, 255, 0), font=font)
                    d.text((6, y + 50), k[2][:16], fill=(200, 200, 200), font=font)
                    d.text((6, y + 64), 'src %03d' % k[4], fill=(200, 200, 200), font=font)
                    for i, p in enumerate(paths):
                        r, c = divmod(i, cols - 1)
                        x = (c + 1) * size; yy = y + r * (size + 12)
                        sheet.paste(thumb(p, size - 4), (x + 2, yy + 2))
                        d.text((x + 3, yy + size), 't%d' % i, fill=(0, 0, 0), font=font)
                    d.line([0, y + lines * (size + 12) - 1, cols * size, y + lines * (size + 12) - 1], fill=(160, 160, 160))
                    y += lines * (size + 12)
                fn = os.path.join(outdir, '%s_%s_%02d.png' % (ped[3], name, pn))
                sheet.save(fn); out.append(fn)
            for b in blocks:
                bh = b[3] * (size + 12)
                if page and h + bh > maxh:
                    flush(page, pn); pn += 1; page, h = [], 0
                page.append(b); h += bh
            if page: flush(page, pn)
    return out

if __name__ == '__main__':
    import argparse
    a = argparse.ArgumentParser(); a.add_argument('--sel'); a.add_argument('--out'); a.add_argument('--slots', default=''); a.add_argument('--peds', default='')
    a.add_argument('roots', nargs='+'); o = a.parse_args()
    for f in run(o.roots, o.sel, o.out, slots=[s for s in o.slots.split(',') if s] or None, peds=[p for p in o.peds.split(',') if p] or None): print(f)
