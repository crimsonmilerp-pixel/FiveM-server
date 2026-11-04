"""Writes a ped clothing collection .ymt (CPedVariationInfo, RSC7 'Meta' resource v2).
Ported from CodeWalker.Core MetaBuilder / ResourceBuilder.AssignPositionsForMeta and
grzyClothTool BuildYMT. Little-endian. Also has a reader used to self-check."""
import struct, zlib

def joaat(s):
    h = 0
    for c in s.encode():
        h = (h + c) & 0xFFFFFFFF; h = (h + (h << 10)) & 0xFFFFFFFF; h ^= h >> 6
    h = (h + (h << 3)) & 0xFFFFFFFF; h ^= h >> 11; h = (h + (h << 15)) & 0xFFFFFFFF
    return h

H = joaat
ARRAYINFO = 0x100
# data types
BOOL, UBYTE, USHORT, UINT, FLOAT, HASH, ARRAY, ARRBYTES, STRUCT = 0x01, 0x11, 0x13, 0x15, 0x21, 0x4A, 0x52, 0x50, 0x05
INTENUM, SHORTFLAGS, INTFLAGS1, INTFLAGS2 = 0x62, 0x64, 0x63, 0x65

def E(name, off, dtype, unk9=0, refidx=0, refkey=0):
    n = name if isinstance(name, int) else H(name)
    k = refkey if isinstance(refkey, int) else H(refkey)
    return (n, off, dtype, unk9, refidx, k)

# (name, key, unknown8h, size, entries) - copied from CodeWalker MetaTypes.GetStructureInfo
STRUCTS = {
 'CPedVariationInfo': (4030871161, 768, 112, [
    E('bHasTexVariations', 0, BOOL), E('bHasDrawblVariations', 1, BOOL), E('bHasLowLODs', 2, BOOL), E('bIsSuperLOD', 3, BOOL),
    E(ARRAYINFO, 0, UBYTE), E('availComp', 4, ARRBYTES, 0, 4, 12),
    E(ARRAYINFO, 0, STRUCT, 0, 0, 'CPVComponentData'), E('aComponentData3', 16, ARRAY, 0, 6),
    E(ARRAYINFO, 0, STRUCT, 0, 0, 'CPedSelectionSet'), E('aSelectionSets', 32, ARRAY, 0, 8),
    E(ARRAYINFO, 0, STRUCT, 0, 0, 'CComponentInfo'), E('compInfos', 48, ARRAY, 0, 10),
    E('propInfo', 64, STRUCT, 0, 0, 'CPedPropInfo'), E('dlcName', 104, HASH)]),
 'CPedPropInfo': (1792487819, 768, 40, [
    E('numAvailProps', 0, UBYTE),
    E(ARRAYINFO, 0, STRUCT, 0, 0, 'CPedPropMetaData'), E('aPropMetaData', 8, ARRAY, 0, 1),
    E(ARRAYINFO, 0, STRUCT, 0, 0, 'CAnchorProps'), E('aAnchors', 24, ARRAY, 0, 3)]),
 'CPedPropTexData': (2767296137, 512, 12, [
    E('inclusions', 0, INTFLAGS2, 0, 32), E('exclusions', 4, INTFLAGS2, 0, 32), E('texId', 8, UBYTE),
    E('inclusionId', 9, UBYTE), E('exclusionId', 10, UBYTE), E('distribution', 11, UBYTE)]),
 'CAnchorProps': (403574180, 768, 24, [
    E(ARRAYINFO, 0, UBYTE), E('props', 0, ARRAY), E('anchor', 16, INTENUM, 0, 0, 'eAnchorPoints')]),
 'CComponentInfo': (3693847250, 512, 48, [
    E(802196719, 0, HASH), E(4233133352, 4, HASH), E(ARRAYINFO, 0, FLOAT), E(128864925, 8, ARRBYTES, 0, 0, 5),
    E('flags', 28, UINT), E('inclusions', 32, INTFLAGS2, 0, 32), E('exclusions', 36, INTFLAGS2, 0, 32),
    E(1613922652, 40, SHORTFLAGS, 0, 16, 'ePedVarComp'), E(2114993291, 42, USHORT), E(3509540765, 44, UBYTE), E(4196345791, 45, UBYTE)]),
 'CPVComponentData': (2024084511, 768, 24, [
    E('numAvailTex', 0, UBYTE), E(ARRAYINFO, 0, STRUCT, 0, 0, 'CPVDrawblData'), E('aDrawblData3', 8, ARRAY, 0, 1)]),
 'CPVDrawblData': (124073662, 768, 48, [
    E('propMask', 0, UBYTE), E('numAlternatives', 1, UBYTE), E(ARRAYINFO, 0, STRUCT, 0, 0, 'CPVTextureData'),
    E('aTexData', 8, ARRAY, 0, 2), E('clothData', 24, STRUCT, 0, 0, 'CPVDrawblData__CPVClothComponentData')]),
 'CPVDrawblData__CPVClothComponentData': (508935687, 0, 24, [E('ownsCloth', 0, BOOL)]),
 'CPVTextureData': (4272717794, 0, 3, [E('texId', 0, UBYTE), E('distribution', 1, UBYTE)]),
 'CPedPropMetaData': (2029738350, 768, 56, [
    E('audioId', 0, HASH), E(ARRAYINFO, 0, FLOAT), E('expressionMods', 4, ARRBYTES, 0, 1, 5),
    E(ARRAYINFO, 0, STRUCT, 0, 0, 'CPedPropTexData'), E('texData', 24, ARRAY, 0, 3),
    E('renderFlags', 40, INTFLAGS1, 0, 3, 'ePropRenderFlags'), E('propFlags', 44, UINT), E('flags', 48, USHORT),
    E('anchorId', 50, UBYTE), E('propId', 51, UBYTE), E(2894625425, 52, UBYTE)]),
}
STRUCT_ORDER = ['CPedVariationInfo', 'CPedPropInfo', 'CPedPropTexData', 'CAnchorProps', 'CComponentInfo',
                'CPVComponentData', 'CPVDrawblData', 'CPVDrawblData__CPVClothComponentData', 'CPVTextureData', 'CPedPropMetaData']
ENUMS = {
 'ePedVarComp': (3472084374, [('PV_COMP_INVALID', -1), ('PV_COMP_HEAD', 0), ('PV_COMP_BERD', 1), ('PV_COMP_HAIR', 2),
    ('PV_COMP_UPPR', 3), ('PV_COMP_LOWR', 4), ('PV_COMP_HAND', 5), ('PV_COMP_FEET', 6), ('PV_COMP_TEEF', 7),
    ('PV_COMP_ACCS', 8), ('PV_COMP_TASK', 9), ('PV_COMP_DECL', 10), ('PV_COMP_JBIB', 11), ('PV_COMP_MAX', 12)]),
 'eAnchorPoints': (1309372691, [('ANCHOR_HEAD', 0), ('ANCHOR_EYES', 1), ('ANCHOR_EARS', 2), ('ANCHOR_MOUTH', 3),
    ('ANCHOR_LEFT_HAND', 4), ('ANCHOR_RIGHT_HAND', 5), ('ANCHOR_LEFT_WRIST', 6), ('ANCHOR_RIGHT_WRIST', 7),
    ('ANCHOR_HIP', 8), ('ANCHOR_LEFT_FOOT', 9), ('ANCHOR_RIGHT_FOOT', 10), ('ANCHOR_PH_L_HAND', 11),
    ('ANCHOR_PH_R_HAND', 12), ('NUM_ANCHORS', 13)]),
 'ePropRenderFlags': (1551913633, [('PRF_ALPHA', 0), ('PRF_DECAL', 1), ('PRF_CUTOUT', 2)]),
}
ENUM_ORDER = ['ePedVarComp', 'eAnchorPoints', 'ePropRenderFlags']
UBYTE_T = 17  # MetaTypeName.BYTE

def pad16(b):
    r = len(b) % 16
    return b + b'\0' * ((16 - r) % 16)

class Builder:
    MAX_BLOCK = 0x4000
    def __init__(self):
        self.blocks = []  # [typehash, bytearray]
    def ensure(self, t):
        for i, (bt, data) in enumerate(self.blocks):
            if bt == t and len(data) < self.MAX_BLOCK:
                return i
        self.blocks.append([t, bytearray()])
        return len(self.blocks) - 1
    def add_array(self, t, data, count):
        """Returns 16-byte Array_Structure (empty if count == 0)."""
        if count == 0:
            return b'\0' * 16
        i = self.ensure(t)
        off = len(self.blocks[i][1])
        self.blocks[i][1] += pad16(data)
        ptr = ((i + 1) & 0xFFF) | ((off & 0xFFFFF) << 12)
        return struct.pack('<QHHI', ptr, count, count, 0)
    def add_item(self, t, data):
        i = self.ensure(t)
        off = len(self.blocks[i][1])
        self.blocks[i][1] += pad16(data)
        return i, off

def build_variation(dlc_name, components, props):
    """components: {compIndex: [ {textures:int, texId:int, propMask:int, alternatives:int, cloth:bool, heels:float}, ...]}
       props: {anchorIndex: [ {textures:int}, ... ]}  (drawable order = list order)"""
    b = Builder()
    b.ensure(H('CPedVariationInfo'))  # block 1 = root
    avail = [255] * 12
    comp_structs = []
    n = 0
    for ci in range(12):
        ds = components.get(ci) or []
        if not ds:
            continue
        avail[ci] = n; n += 1
        draw_bytes = b''
        for d in ds:
            tex = b''.join(struct.pack('<BB', d.get('texId', 0), 255) + b'\0' for _ in range(d['textures']))
            # CPVTextureData is 3 bytes (texId, distribution, pad)
            arr = b.add_array(H('CPVTextureData'), tex, d['textures'])
            draw_bytes += struct.pack('<BB6x', d.get('propMask', 1), d.get('alternatives', 0)) + arr + struct.pack('<B23x', 1 if d.get('cloth') else 0)
        darr = b.add_array(H('CPVDrawblData'), draw_bytes, len(ds))
        comp_structs.append(struct.pack('<B7x', sum(d['textures'] for d in ds) & 0xFF) + darr)
    comps_arr = b.add_array(H('CPVComponentData'), b''.join(comp_structs), len(comp_structs))
    infos = b''
    count = 0
    none = H('none')
    for ci in range(12):
        for di, d in enumerate(components.get(ci) or []):
            infos += struct.pack('<II5fIiiHHBB2x', none, none, 0, 0, 0, 0, d.get('heels', 0.0), 0, 0, 0, 0, 0, ci, di)
            count += 1
    infos_arr = b.add_array(H('CComponentInfo'), infos, count)
    # props
    pmeta = b''; pcount = 0; anchors = []
    for ai in sorted(props):
        for pi, p in enumerate(props[ai]):
            tex = b''.join(struct.pack('<iiBBBB', 0, 0, t, 0, 0, 255) for t in range(p['textures']))
            tarr = b.add_array(H('CPedPropTexData'), tex, p['textures'])
            pmeta += struct.pack('<I5f', none, 0, 0, 0, 0, 0) + tarr + struct.pack('<iIHBBB3x', 0, 0, 0, ai, pi, 0)
            pcount += 1
        anchors.append(ai)
    pmeta_arr = b.add_array(H('CPedPropMetaData'), pmeta, pcount)
    anc = b''
    for ai in anchors:
        counts = bytes(p['textures'] for p in props[ai])
        barr = b.add_array(UBYTE_T, counts, len(counts))
        anc += barr + struct.pack('<i4x', ai)
    anc_arr = b.add_array(H('CAnchorProps'), anc, len(anchors))
    propinfo = struct.pack('<B7x', pcount & 0xFF) + pmeta_arr + anc_arr
    root = struct.pack('<BBBB', 1, 1, 0, 0) + bytes(avail) + comps_arr + b'\0' * 16 + infos_arr + propinfo + struct.pack('<I4x', H(dlc_name))
    assert len(root) == 112, len(root)
    i, off = b.add_item(H('CPedVariationInfo'), root)
    assert (i, off) == (0, len(b.blocks[0][1]) - 112)
    return build_meta(b, dlc_name, root_block_index=1)

def build_meta(b, name, root_block_index):
    # ---- collect resource blocks in CodeWalker's order ----
    blocks = []  # (key, length, writer)
    si_list = [(STRUCTS[n], n) for n in STRUCT_ORDER]
    en_list = [(ENUMS[n], n) for n in ENUM_ORDER]
    sizes = {}
    order = ['meta', 'pages', 'sinfos'] + ['sent%d' % i for i in range(len(si_list))] + ['einfos'] + \
            ['eent%d' % i for i in range(len(en_list))] + ['dblocks'] + ['data%d' % i for i in range(len(b.blocks))] + ['name']
    sizes['meta'] = 112
    sizes['pages'] = 20 + 256 * 16
    sizes['sinfos'] = 32 * len(si_list)
    for i, ((key, unk, size, ents), n) in enumerate(si_list): sizes['sent%d' % i] = 16 * len(ents)
    sizes['einfos'] = 24 * len(en_list)
    for i, ((key, ents), n) in enumerate(en_list): sizes['eent%d' % i] = 8 * len(ents)
    sizes['dblocks'] = 16 * len(b.blocks)
    for i, (t, data) in enumerate(b.blocks): sizes['data%d' % i] = len(data)
    sizes['name'] = len(name) + 1
    # ---- AssignPositionsForMeta ----
    largest = max(sizes.values())
    page = 0x2000
    while page < largest: page *= 2
    while True:
        pos = {}; pages = 0; cur = 0
        for k in order:
            L = sizes[k]
            if pages * page - cur < L + 16:
                pages += 1; cur = page * (pages - 1)
            pos[k] = cur; cur += L
            if cur % 16: cur += 16 - cur % 16
        if pages < 128: break
        page *= 2
    ss = 0; bs = page
    while bs > 0x200: ss += 1; bs >>= 1
    c = pages
    sysflags = ((c & 1) << 27) | (((c >> 1) & 1) << 26) | (((c >> 2) & 1) << 25) | (((c >> 3) & 1) << 24) | (((c >> 4) & 0x7F) << 17) | (ss & 0xF)
    page_count = bin(c & 0xF).count('1') + (c >> 4)
    total = page * pages
    buf = bytearray(total)
    P = lambda k: 0x50000000 + pos[k]
    def put(k, data):
        assert len(data) == sizes[k], (k, len(data), sizes[k])
        buf[pos[k]:pos[k] + len(data)] = data
    put('meta', struct.pack('<IIQ', 0x405bc808, 1, P('pages')) +
        struct.pack('<ihBBiiqqqqqhhhh', 0x50524430, 0x79, 0, 0, 0, root_block_index, P('sinfos'), P('einfos'), P('dblocks'), P('name'), 0,
                    len(si_list), len(en_list), len(b.blocks), 0) + b'\0' * 32)
    put('pages', struct.pack('<IIBBHII', 0, 0, page_count, 0, 0, 0, 0) + b'\0' * 4096)
    sinfos = b''
    for i, ((key, unk, size, ents), n) in enumerate(si_list):
        sinfos += struct.pack('<IIIIqihh', H(n), key, unk, 0, P('sent%d' % i), size, 0, len(ents))
        put('sent%d' % i, b''.join(struct.pack('<IiBBhI', *e) for e in ents))
    put('sinfos', sinfos)
    einfos = b''
    for i, ((key, ents), n) in enumerate(en_list):
        einfos += struct.pack('<IIqii', H(n), key, P('eent%d' % i), len(ents), 0)
        put('eent%d' % i, b''.join(struct.pack('<Ii', H(en), v) for en, v in ents))
    put('einfos', einfos)
    dbl = b''
    for i, (t, data) in enumerate(b.blocks):
        dbl += struct.pack('<Iiq', t, len(data), P('data%d' % i))
        put('data%d' % i, bytes(data))
    put('dblocks', dbl)
    put('name', name.encode('ascii') + b'\0')
    comp = zlib.compressobj(9, zlib.DEFLATED, -15)
    cdata = comp.compress(bytes(buf)) + comp.flush()
    version = 2
    gfxflags = (version & 0xF) << 28
    return struct.pack('<IiII', 0x37435352, version, sysflags, gfxflags) + cdata

# ------------------------------------------------------------------ reader (self-check)
def size_from_flags(flags):
    s = [((flags >> 27) & 1), ((flags >> 26) & 1) << 1, ((flags >> 25) & 1) << 2, ((flags >> 24) & 1) << 3,
         ((flags >> 17) & 0x7F) << 4, ((flags >> 11) & 0x3F) << 5, ((flags >> 7) & 0xF) << 6, ((flags >> 5) & 3) << 7, ((flags >> 4) & 1) << 8]
    return (0x200 << (flags & 0xF)) * sum(s)

def read_rsc(data):
    magic, ver, sf, gf = struct.unpack('<IiII', data[:16])
    assert magic == 0x37435352
    raw = zlib.decompress(data[16:], -15)
    ss, gs = size_from_flags(sf), size_from_flags(gf)
    assert len(raw) == ss + gs, (len(raw), ss, gs)
    return ver, raw[:ss], raw[ss:]

def read_meta(data):
    ver, sysd, gfx = read_rsc(data)
    R = lambda p: p - 0x50000000
    vft, unk, pagesptr = struct.unpack_from('<IIQ', sysd, 0)
    f = struct.unpack_from('<ihBBiiqqqqqhhhh', sysd, 16)
    root, sp, ep, dp, np_ = f[5], f[6], f[7], f[8], f[9]
    scount, ecount, dcount = f[11], f[12], f[13]
    name = sysd[R(np_):sysd.index(b'\0', R(np_))].decode()
    blocks = []
    for i in range(dcount):
        t, L, p = struct.unpack_from('<Iiq', sysd, R(dp) + 16 * i)
        blocks.append((t, sysd[R(p):R(p) + L]))
    structs = {}
    for i in range(scount):
        nh, key, unk8, unkc, ep2, size, u1c, cnt = struct.unpack_from('<IIIIqihh', sysd, R(sp) + 32 * i)
        structs[nh] = (size, [struct.unpack_from('<IiBBhI', sysd, R(ep2) + 16 * j) for j in range(cnt)])
    return dict(version=ver, vft=vft, root=root, name=name, blocks=blocks, structs=structs)

def deref(meta, arr):
    ptr, c1, c2, u = struct.unpack('<QHHI', arr)
    if c1 == 0: return None, 0
    bid = ptr & 0xFFF; off = (ptr >> 12) & 0xFFFFF
    return meta['blocks'][bid - 1][1][off:], c1

def dump_variation(data):
    m = read_meta(data)
    t, rb = m['blocks'][m['root'] - 1]
    assert t == H('CPedVariationInfo')
    root = rb[len(rb) - 112:] if False else rb[-112:]
    out = {'name': m['name'], 'avail': list(root[4:16]), 'comps': [], 'props': [], 'anchors': []}
    cd, cn = deref(m, root[16:32])
    for i in range(cn):
        c = cd[24 * i:24 * i + 24]
        dd, dn = deref(m, c[8:24])
        draws = []
        for j in range(dn):
            d = dd[48 * j:48 * j + 48]
            td, tn = deref(m, d[8:24])
            draws.append(dict(propMask=d[0], alt=d[1], cloth=d[24], tex=[(td[3 * k], td[3 * k + 1]) for k in range(tn)]))
        out['comps'].append(dict(numAvailTex=c[0], draws=draws))
    idd, inn = deref(m, root[48:64])
    out['compInfos'] = [struct.unpack_from('<II5fIiiHHBB', idd, 48 * k) for k in range(inn)]
    pi = root[64:104]
    out['numAvailProps'] = pi[0]
    pd, pn = deref(m, pi[8:24])
    for k in range(pn):
        p = pd[56 * k:56 * k + 56]
        td, tn = deref(m, p[24:40])
        out['props'].append(dict(anchor=p[50], propId=p[51], tex=[struct.unpack_from('<iiBBBB', td, 12 * x) for x in range(tn)]))
    ad, an = deref(m, pi[24:40])
    for k in range(an):
        a = ad[24 * k:24 * k + 24]
        bd, bn = deref(m, a[0:16])
        out['anchors'].append((struct.unpack_from('<i', a, 16)[0], list(bd[:bn])))
    out['dlcName'] = struct.unpack_from('<I', root, 104)[0]
    return out
