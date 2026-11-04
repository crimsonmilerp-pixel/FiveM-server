"""Bounding boxes of the drawables in a .ydd (to see where on the body a piece sits)."""
import struct, zlib, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ymt import size_from_flags
def bbox(path):
    data = open(path, 'rb').read()
    magic, ver, sf, gf = struct.unpack('<IiII', data[:16])
    raw = zlib.decompress(data[16:], -15)
    sysd = raw[:size_from_flags(sf)]
    S = lambda p: p - 0x50000000
    dptr, dcount = struct.unpack_from('<QH', sysd, 0x30)
    out = []
    for i in range(dcount):
        p = S(struct.unpack_from('<Q', sysd, S(dptr) + 8 * i)[0])
        c = struct.unpack_from('<3ff', sysd, p + 0x20)
        mn = struct.unpack_from('<3f', sysd, p + 0x30); mx = struct.unpack_from('<3f', sysd, p + 0x40)
        out.append(dict(center=c[:3], radius=c[3], min=mn, max=mx))
    return out

def positions(path, normals=False):
    """All vertex positions of the high-detail models (bind pose)."""
    data = open(path, 'rb').read()
    magic, ver, sf, gf = struct.unpack('<IiII', data[:16])
    raw = zlib.decompress(data[16:], -15)
    ss = size_from_flags(sf)
    sysd, gfx = raw[:ss], raw[ss:]
    def seg(p):
        return (sysd, p - 0x50000000) if p < 0x60000000 else (gfx, p - 0x60000000)
    S = lambda p: p - 0x50000000
    dptr, dcount = struct.unpack_from('<QH', sysd, 0x30)
    pts = []
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
                stride, flags = struct.unpack_from('<HH', sysd, vb + 0x8)
                dp, vc = struct.unpack_from('<QI', sysd, vb + 0x10)
                if dp < 0x50000000:
                    dp = struct.unpack_from('<Q', sysd, g + 0x78)[0]
                if dp < 0x50000000 or vc == 0:
                    continue
                info = S(struct.unpack_from('<Q', sysd, vb + 0x30)[0])
                dflags, dstride, _u, _c, types = struct.unpack_from('<IHBBQ', sysd, info)
                buf, off = seg(dp)
                if not (dflags & 1): continue
                SIZES = {0: 0, 1: 4, 2: 4, 3: 8, 4: 0, 5: 8, 6: 12, 7: 16, 8: 4, 9: 4, 10: 4}
                noff = None; o = 0
                for e in range(16):
                    if dflags & (1 << e):
                        t = (types >> (e * 4)) & 0xF
                        if e == 3: noff = (o, t)
                        o += SIZES.get(t, 0)
                for v in range(vc):
                    base = off + v * dstride
                    pos = struct.unpack_from('<3f', buf, base)
                    if normals:
                        n = (0.0, 0.0, 0.0)
                        if noff and noff[1] == 6: n = struct.unpack_from('<3f', buf, base + noff[0])
                        pts.append((pos, n))
                    else:
                        pts.append(pos)
    return pts
