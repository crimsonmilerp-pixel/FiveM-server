# Copied from the uniform conversion work (Nov 3, 2026). See docs/eup/README.md
# Minimal RPF7 (OPEN, unencrypted) reader: list + extract.
import struct, sys, os

def read_toc(path):
    f = open(path, 'rb')
    magic, count, nlen, enc = struct.unpack('<4sIII', f.read(16))
    assert magic == b'7FPR', magic
    assert enc == 0x4E45504F, hex(enc)  # OPEN
    ent = f.read(count * 16)
    names = f.read(nlen)
    def name(off):
        end = names.index(b'\0', off)
        return names[off:end].decode('latin1')
    entries = []
    for i in range(count):
        e = ent[i*16:(i+1)*16]
        a, b = struct.unpack('<II', e[:8])
        if b == 0x7FFFFF00:
            noff, _, idx, cnt = struct.unpack('<IIII', e)
            entries.append(dict(kind='dir', name=name(noff), idx=idx, cnt=cnt))
        else:
            lo = struct.unpack('<Q', e[:8])[0]
            noff = lo & 0xFFFF
            size = (lo >> 16) & 0xFFFFFF
            off = (lo >> 40) & 0xFFFFFF
            if off & 0x800000:
                sysf, gfxf = struct.unpack('<II', e[8:])
                entries.append(dict(kind='res', name=name(noff), size=size, off=off & 0x7FFFFF, sysf=sysf, gfxf=gfxf))
            else:
                usize, fenc = struct.unpack('<II', e[8:])
                entries.append(dict(kind='bin', name=name(noff), size=size, off=off, usize=usize, enc=fenc))
    return f, entries

def walk(entries, i=0, prefix=''):
    e = entries[i]
    if e['kind'] == 'dir':
        p = prefix + e['name'] + '/' if i else ''
        for j in range(e['idx'], e['idx'] + e['cnt']):
            yield from walk(entries, j, p)
    else:
        yield prefix + e['name'], e

def data(f, e):
    f.seek(e['off'] * 512)
    size = e['size']
    if e['kind'] == 'bin':
        n = size if size else e['usize']
        return f.read(n)
    # resource
    if size == 0xFFFFFF:
        hdr = f.read(16)
        size = (hdr[7] << 0) | (hdr[14] << 8) | (hdr[5] << 16) | (hdr[2] << 24)
        f.seek(e['off'] * 512)
    return f.read(size)

if __name__ == '__main__':
    cmd, path = sys.argv[1], sys.argv[2]
    f, entries = read_toc(path)
    if cmd == 'list':
        for p, e in walk(entries):
            print(e['kind'], e['size'], p)
    elif cmd == 'extract':
        out = sys.argv[3]
        n = 0
        for p, e in walk(entries):
            d = data(f, e)
            dest = os.path.join(out, p)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            open(dest, 'wb').write(d)
            n += 1
        print('extracted', n)
