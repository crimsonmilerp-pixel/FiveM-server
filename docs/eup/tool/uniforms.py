"""The LSPD rank uniforms, as numbers inside the rp_eup pack (slot name, piece, texture).
Base game pieces (arms, shoes, 'none') are given as ('base', number, texture)."""
SLOTS = {  # illenium outfitData key -> (component or prop id, our slot name)
    'mask': (1, 'berd'), 'arms': (3, 'uppr'), 'pants': (4, 'lowr'), 'bag': (5, 'hand'), 'shoes': (6, 'feet'),
    'accessory': (7, 'teef'), 't-shirt': (8, 'accs'), 'vest': (9, 'task'), 'decals': (10, 'decl'), 'torso2': (11, 'jbib'),
    'hat': (0, 'p_head'),
}
NONE = ('base', 0, 0)
RANKS = ['Cadet', 'Officer I', 'Officer II', 'Officer III', 'Sergeant', 'Lieutenant', 'Captain', 'Chief']

def build(g):
    """g = 'Male' or 'Female'. Returns list of outfits: dict(name, grades, data{key: piece})."""
    m = g == 'Male'
    P = {  # pieces per gender (numbers inside rp_eup; texture index)
        'short': ('jbib', 40 if m else 36, 1), 'long': ('jbib', 41 if m else 37, 1), 'tie': ('jbib', 42 if m else 39, 1),
        'pants': ('lowr', 6 if m else 5, 0), 'belt': ('accs', 7 if m else 7, 0), 'radio': ('task', 22, 0),
        'badge': lambda t: ('hand', 26 if m else 21, t),
        'stripes_short': lambda t: ('decl', 6 if m else 5, t), 'stripes_long': lambda t: ('decl', 16 if m else 15, t),
        'collar': lambda t: ('decl', 13 if m else 12, t), 'stars4': ('decl', 12 if m else 11, 0),
        'cap': ('p_head', 0, 0),
        'arms_short': ('base', 0 if m else 14, 0), 'arms_long': ('base', 1 if m else 14, 0),
        'shoes': ('base', 51 if m else 52, 0),
    }
    def outfit(name, grades, top, arms, badge, decal, hat=False):
        d = {'torso2': top, 'arms': arms, 'pants': P['pants'], 't-shirt': P['belt'], 'vest': P['radio'],
             'bag': badge, 'decals': decal or NONE, 'shoes': P['shoes'], 'mask': NONE,
             'accessory': NONE,
             'hat': P['cap'] if hat else ('base', -1, -1)}
        return dict(name=name, grades=grades, data=d)
    out = []
    # Cadet: one plain uniform, no choices
    out.append(outfit('Cadet: Short Sleeve', [0], P['short'], P['arms_short'], P['badge'](0), None))
    # Officers and Sergeant: sleeve stripes show the rank
    for grade, rank, stripe, badge in ((1, 'Officer I', None, 0), (2, 'Officer II', 0, 0), (3, 'Officer III', 1, 0), (4, 'Sergeant', 2, 1)):
        ds = P['stripes_short'](stripe) if stripe is not None else None
        dl = P['stripes_long'](stripe) if stripe is not None else None
        out.append(outfit('%s: Short Sleeve' % rank, [grade], P['short'], P['arms_short'], P['badge'](badge), ds))
        out.append(outfit('%s: Long Sleeve' % rank, [grade], P['long'], P['arms_long'], P['badge'](badge), dl))
        out.append(outfit('%s: Long Sleeve and Cap' % rank, [grade], P['long'], P['arms_long'], P['badge'](badge), dl, hat=True))
    # Command staff: closed collar with the tie built into the shirt, gold collar insignia, rank on the badge
    for grade, rank, decal, badge in ((5, 'Lieutenant', P['collar'](6), 2), (6, 'Captain', P['collar'](7), 3), (7, 'Chief', P['stars4'], 8)):
        out.append(outfit('%s: Command Uniform' % rank, [grade], P['tie'], P['arms_long'], P['badge'](badge), decal))
        out.append(outfit('%s: Command Uniform and Cap' % rank, [grade], P['tie'], P['arms_long'], P['badge'](badge), decal, hat=True))
    return out
