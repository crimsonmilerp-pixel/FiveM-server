"""Final lookbook: one column per rank, full uniform on top, rank insignia close-up below."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw, ImageFont
import render, uniforms, lookbook
gender = sys.argv[1]; out = sys.argv[2]
outs = {o['name']: o for o in uniforms.build(gender)}
cols = [('Cadet', 'Cadet: Short Sleeve', 'side'), ('Officer I', 'Officer I: Long Sleeve', 'side'),
        ('Officer II', 'Officer II: Short Sleeve', 'side'), ('Officer III', 'Officer III: Long Sleeve', 'side'),
        ('Sergeant', 'Sergeant: Short Sleeve', 'side'), ('Lieutenant', 'Lieutenant: Command Uniform', 'front'),
        ('Captain', 'Captain: Command Uniform', 'front'), ('Chief', 'Chief: Command Uniform', 'front')]
W, H, CH = 250, 470, 250
try:
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 18)
    small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 12)
except Exception:
    font = small = ImageFont.load_default()
sheet = Image.new('RGB', (W * len(cols), 40 + H + CH + 40), (245, 245, 245)); d = ImageDraw.Draw(sheet)
for i, (rank, name, view) in enumerate(cols):
    ps = lookbook.parts_of(gender, outs[name])
    full = render.render(ps, size=(W, H), view='front', zrange=(-1.05, 0.95), bg=(245, 245, 245))
    if view == 'side':
        close = render.render(ps, size=(W, CH), view='side', zrange=(0.15, 0.62), bg=(232, 232, 236))
    else:
        close = render.render(ps, size=(W, CH), view='front', zrange=(0.38, 0.66), bg=(232, 232, 236))
    x = i * W
    d.text((x + 10, 10), rank, fill=(20, 20, 40), font=font)
    sheet.paste(full, (x, 40)); sheet.paste(close, (x, 40 + H))
    d.text((x + 10, 40 + H + CH + 8), name.split(': ')[1], fill=(80, 80, 90), font=small)
sheet.save(out); print(out, sheet.size)
