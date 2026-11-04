"""Tiny software renderer for ped clothing (front/side views) to check how pieces sit together."""
import struct, zlib, sys, os, json
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
from ymt import size_from_flags
import ytd

SIZES = {0: 0, 1: 4, 2: 4, 3: 8, 4: 0, 5: 8, 6: 12, 7: 16, 8: 4, 9: 4, 10: 4}

def mesh(path):
    data = open(path, 'rb').read()
    magic, ver, sf, gf = struct.unpack('<IiII', data[:16])
    raw = zlib.decompress(data[16:], -15)
    ss = size_from_flags(sf); sysd, gfx = raw[:ss], raw[ss:]
    seg = lambda p: (sysd, p - 0x50000000) if p < 0x60000000 else (gfx, p - 0x60000000)
    S = lambda p: p - 0x50000000
    dptr, dcount = struct.unpack_from('<QH', sysd, 0x30)
    out = []
    for i in range(dcount):
        d = S(struct.unpack_from('<Q', sysd, S(dptr) + 8 * i)[0])
        hp = struct.unpack_from('<Q', sysd, d + 0x50)[0]
        if not hp: continue
        lp, lc = struct.unpack_from('<QH', sysd, S(hp))
        for m in range(lc):
            mp = S(struct.unpack_from('<Q', sysd, S(lp) + 8 * m)[0])
            gp, gc = struct.unpack_from('<QH', sysd, mp + 0x8)
            for gi in range(gc):
                g = S(struct.unpack_from('<Q', sysd, S(gp) + 8 * gi)[0])
                vb = S(struct.unpack_from('<Q', sysd, g + 0x18)[0])
                ib = S(struct.unpack_from('<Q', sysd, g + 0x38)[0])
                dp, vc = struct.unpack_from('<QI', sysd, vb + 0x10)
                if dp < 0x50000000: dp = struct.unpack_from('<Q', sysd, g + 0x78)[0]
                if dp < 0x50000000: dp = struct.unpack_from('<Q', sysd, vb + 0x20)[0]
                if dp < 0x50000000 or vc == 0:
                    print('  (skip geometry without vertex data in %s)' % os.path.basename(path)); continue
                info = S(struct.unpack_from('<Q', sysd, vb + 0x30)[0])
                dflags, dstride, _u, _c, types = struct.unpack_from('<IHBBQ', sysd, info)
                offs = {}; o = 0
                for e in range(16):
                    if dflags & (1 << e):
                        t = (types >> (e * 4)) & 0xF; offs[e] = (o, t); o += SIZES.get(t, 0)
                icount = struct.unpack_from('<I', sysd, ib + 0x8)[0]
                ip = struct.unpack_from('<Q', sysd, ib + 0x10)[0]
                buf, off = seg(dp); ibuf, ioff = seg(ip)
                if off + vc * dstride > len(buf) or ioff + icount * 2 > len(ibuf):
                    print('  (skip geometry outside buffer in %s: dp %x vc %d stride %d)' % (os.path.basename(path), dp, vc, dstride)); continue
                arr = np.frombuffer(buf, dtype=np.uint8, count=vc * dstride, offset=off).reshape(vc, dstride)
                pos = arr[:, 0:12].copy().view('<f4').reshape(vc, 3)
                uv = np.zeros((vc, 2), np.float32)
                if 6 in offs:
                    o6, t6 = offs[6]
                    if t6 == 1: uv = arr[:, o6:o6 + 4].copy().view('<f2').reshape(vc, 2).astype(np.float32)
                    elif t6 == 5: uv = arr[:, o6:o6 + 8].copy().view('<f4').reshape(vc, 2)
                nrm = np.zeros((vc, 3), np.float32)
                if 3 in offs and offs[3][1] == 6:
                    o3 = offs[3][0]; nrm = arr[:, o3:o3 + 12].copy().view('<f4').reshape(vc, 3)
                idx = np.frombuffer(ibuf, dtype='<u2', count=icount, offset=ioff).reshape(-1, 3)
                out.append((pos, uv, nrm, idx))
    return out

def load_tex(path):
    im = ytd.to_image(ytd.textures(open(path, 'rb').read())[0]).convert('RGBA')
    return np.asarray(im).astype(np.float32) / 255.0

def render(parts, size=(420, 760), view='front', zrange=(-1.05, 0.8), xrange=None, bg=(235, 235, 235)):
    W, H = size
    zb = np.full((H, W), np.inf, np.float32)
    img = np.zeros((H, W, 3), np.float32); img[:] = np.array(bg) / 255.0
    z0, z1 = zrange
    scale = H / (z1 - z0)
    cx = W / 2
    for path, texpath in parts:
        tex = load_tex(texpath); th, tw = tex.shape[:2]
        for pos, uv, nrm, idx in mesh(path):
            if view == 'front': sx, depth, nd = pos[:, 0], pos[:, 1], -nrm[:, 1]
            elif view == 'back': sx, depth, nd = -pos[:, 0], -pos[:, 1], nrm[:, 1]
            else: sx, depth, nd = pos[:, 1], -pos[:, 0], nrm[:, 0]  # seen from the ped's left side
            X = cx + sx * scale; Y = (z1 - pos[:, 2]) * scale
            for a, b, c in idx:
                xs = np.array([X[a], X[b], X[c]]); ys = np.array([Y[a], Y[b], Y[c]])
                x0, x1 = int(max(0, np.floor(xs.min()))), int(min(W - 1, np.ceil(xs.max())))
                y0, y1 = int(max(0, np.floor(ys.min()))), int(min(H - 1, np.ceil(ys.max())))
                if x1 < x0 or y1 < y0: continue
                den = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
                if abs(den) < 1e-9: continue
                gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
                w0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / den
                w1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / den
                w2 = 1 - w0 - w1
                m = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
                if not m.any(): continue
                dz = w0 * depth[a] + w1 * depth[b] + w2 * depth[c]
                u = w0 * uv[a, 0] + w1 * uv[b, 0] + w2 * uv[c, 0]
                v = w0 * uv[a, 1] + w1 * uv[b, 1] + w2 * uv[c, 1]
                tu = (np.mod(u, 1.0) * (tw - 1)).astype(int); tv = (np.mod(v, 1.0) * (th - 1)).astype(int)
                col = tex[tv, tu]
                m &= col[..., 3] > 0.4
                sub = zb[y0:y1 + 1, x0:x1 + 1]
                m &= dz < sub
                if not m.any(): continue
                n = np.clip(w0 * nd[a] + w1 * nd[b] + w2 * nd[c], 0, 1)
                shade = (0.45 + 0.75 * n)[..., None]
                sub[m] = dz[m]
                img[y0:y1 + 1, x0:x1 + 1][m] = np.clip(col[..., :3] * shade, 0, 1)[m]
    return Image.fromarray((img * 255).astype(np.uint8))
