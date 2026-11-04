"""Reads GTA V .ytd texture dictionaries (RSC7 v13) and turns textures into PIL images."""
import struct, zlib, io
from PIL import Image
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ymt import size_from_flags

FOURCC = lambda s: struct.unpack('<I', s.encode())[0]
BLOCK = {FOURCC('DXT1'): ('DXT1', 8), FOURCC('DXT3'): ('DXT3', 16), FOURCC('DXT5'): ('DXT5', 16),
         FOURCC('ATI1'): ('ATI1', 8), FOURCC('ATI2'): ('ATI2', 16), FOURCC('BC7 '): ('BC7', 16)}
RAW = {21: ('BGRA', 4), 32: ('RGBA', 4), 28: ('A', 1), 50: ('L', 1)}

def load(data):
    magic, ver, sf, gf = struct.unpack('<IiII', data[:16])
    raw = zlib.decompress(data[16:], -15)
    ss = size_from_flags(sf)
    return raw[:ss], raw[ss:]

def textures(data):
    sysd, gfx = load(data)
    S = lambda p: p - 0x50000000
    G = lambda p: p - 0x60000000
    ptr, cnt = struct.unpack_from('<QH', sysd, 0x30)
    out = []
    for i in range(cnt):
        tp = struct.unpack_from('<Q', sysd, S(ptr) + 8 * i)[0]
        o = S(tp)
        namep = struct.unpack_from('<Q', sysd, o + 0x28)[0]
        name = sysd[S(namep):sysd.index(b'\0', S(namep))].decode('latin1')
        w, h, depth, stride, fmt = struct.unpack_from('<HHHHI', sysd, o + 0x50)
        levels = sysd[o + 0x5D]
        dp = struct.unpack_from('<Q', sysd, o + 0x70)[0]
        out.append(dict(name=name, w=w, h=h, stride=stride, fmt=fmt, levels=levels, data=gfx[G(dp):]))
    return out

def to_image(t):
    w, h, fmt = t['w'], t['h'], t['fmt']
    if fmt in BLOCK:
        kind, bsz = BLOCK[fmt]
        size = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * bsz
        hdr = bytearray(128)
        hdr[0:4] = b'DDS '
        struct.pack_into('<IIIIIII', hdr, 4, 124, 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000, h, w, size, 0, 1)
        struct.pack_into('<II', hdr, 76, 32, 0x4)
        if kind == 'BC7':
            struct.pack_into('<4s', hdr, 84, b'DX10')
            ext = struct.pack('<IIIII', 98, 3, 0, 1, 0)
        else:
            struct.pack_into('<4s', hdr, 84, kind.encode())
            ext = b''
        struct.pack_into('<I', hdr, 108, 0x1000)
        im = Image.open(io.BytesIO(bytes(hdr) + ext + t['data'][:size]))
        im.load()
        return im
    if fmt in RAW:
        mode, bpp = RAW[fmt]
        rows = [t['data'][y * t['stride']:y * t['stride'] + w * bpp] for y in range(h)]
        buf = b''.join(rows)
        if mode == 'BGRA':
            return Image.frombytes('RGBA', (w, h), buf, 'raw', 'BGRA')
        return Image.frombytes(mode, (w, h), buf)
    raise ValueError('format %r' % fmt)
