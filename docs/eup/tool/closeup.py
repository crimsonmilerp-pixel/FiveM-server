import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw
import render, uniforms, lookbook
def up(gender, data, view, extra=None, drop=()):
    ped = lookbook.PED[gender]
    ps = []
    for key, pc in data.items():
        if key in drop or pc is None or pc[0] == 'base': continue
        ps.append(lookbook.piece(ped, *pc))
    for pc in (extra or []): ps.append(lookbook.piece(ped, *pc))
    return render.render(ps, size=(420, 380), view=view, zrange=(0.0, 0.7))
if __name__ == '__main__':
    gender = sys.argv[1]; out = sys.argv[2]
    outs = {o['name']: o for o in uniforms.build(gender)}
    jobs = []
    for spec in sys.argv[3:]:
        name, view, *rest = spec.split('|')
        extra = []; drop = ()
        for r in rest:
            if r.startswith('drop='): drop = tuple(r[5:].split(','))
            elif r.startswith('add='): s, n, t = r[4:].split(':'); extra.append((s, int(n), int(t)))
        jobs.append(('%s (%s) %s' % (name, view, ' '.join(rest)), up(gender, outs[name]['data'], view, extra, drop)))
    cols = 3; rows = (len(jobs) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * 420, rows * 400), 'white'); d = ImageDraw.Draw(sheet)
    for i, (lab, im) in enumerate(jobs):
        x, y = (i % cols) * 420, (i // cols) * 400; sheet.paste(im, (x, y)); d.text((x + 4, y + 384), lab[:70], fill=(0, 0, 0))
    sheet.save(out); print(out, sheet.size)
