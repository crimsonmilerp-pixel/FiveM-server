"""
Clothing rules for our illenium-appearance blacklist (Pillar C: grounded world).
Matched against each clothing item's in-game name (one name per color/texture).
Groups, checked in this order (first match wins):
  festive   - Christmas, Valentine's, Thanksgiving, New Year's party gear. Seasonal: staff can switch on.
  halloween - horror and monster costumes. Seasonal: staff can switch on.
  costume   - cartoon characters, mascots, sci-fi, glowing/LED, apocalypse armor, joke novelty items.
  racy      - lingerie worn as outerwear.
Anything that matches nothing stays visible. Swimwear, underwear basics, bustiers, real
rubber/party-store masks (pig, ape, skull, clown, president, animal heads) stay visible on purpose.
"""

# Applied to every clothing slot.
COMMON = {
    'festive': [
        r'\belf\b', r'\belves\b', r'\bsanta\b', r'reindeer', r'gingerbread', r'christmas', r'festive', r'xmas',
        r'\bnoel\b', r'\bholly\b', r'pudding', r'ugly sweater', r'ho-ho-ho', r'claus', r'candy cane',
        r'krampus', r'abominable', r'joy scarf', r'snowflake scarf', r'bah humbug', r'\btree\b',
        r"season's gre", r'valentine', r"new year's", r'new year glasses', r'independence day',
        r'independence skirt', r'independence tailcoat', r'star tailcoat', r'\bbelieve\b', r'borfmas',
        r'party hat', r'glow sweater', r'trees glow', r'\bcupid\b', r'turkey', r'snowman', r'the gooch',
    ],
    'halloween': [
        r'pumpkin',
    ],
    'costume': [
        r'dunce cap', r'top foam hat', r'usa crown', r'usa boppers', r'beer hat', r'\bdeadline\b',
        r'\bglow\b', r'light ups', r'raider (top|pants|boots)', r'plated boots', r'alien (hooded )?tracksuit',
        r'carnival feather', r'buccaneer', r'star frame shades', r'star spangled shades',
    ],
    'racy': [
        r'lace panties', r'^(?!.*denim).*\bstockings\b',
    ],
}

# Masks only (these words mean other things on a T-shirt).
MASKS = {
    'festive': [r'\bcinco de mayo\b'],
    'halloween': [
        r'^(black|green|red|white|gray|grey) monster$', r'infected', r'mummy', r'vampyr', r'vampire', r'\bfrank\b', r'creepy', r'butler', r'psycho',
        r'flayed', r'skull burst', r'lycanthrope', r'toxic insect', r'sewer creature', r'lucifer',
        r'slasher', r'hypnotic alien', r'witch', r'zombie', r'death bird', r'horned skull', r'stitched wire',
        r'spiked skull', r'^famine$', r'^war$', r'^death$', r'^conquest$', r'cracked puppet',
        r'^(grimy|pale) stitched$', r'calavera', r'vintage devil', r'werewolf', r'vintage skull', r'calaca', r'demon goat',
        r'hooded skull', r'flaming skull', r'jumping spider',
    ],
    'costume': [
        r'^pogo$', r'warrior', r'^impotent rage$', r'impotent rage eye', r'watermelon', r'(luminous|electric|neon)$',
        r'^(grin|cry|laugh|grimace|in love|blow kiss|gasp|wink)$', r'painted$', r'painted rabbit', r'dragon mask', r'clownfish', r'princess robot', r'moorehead', r'beast$',
        r'\bdino\b', r'\boni\b', r'unicorn', r'\brobo\b', r'stalker', r'\braider\b',
        r'marauder', r'paco the taco', r'burger shot mask', r"cluckin' bell mask",
        r'^(strawberry|lemon|grapes|pineapple|cherries) mask$', r'lucky seven', r'joker',
        r'^(king|queen|jack|ace) of (clubs|hearts|spades|diamonds)$', r'baby smile', r'^fig$', r'grinner', r'fluffy rabbit', r'voyeur',
        r'^geo (?!camo).*(fox|cat|pig|dog)$', r'gold mask respirator', r'cerberus',
        r'blow kiss', r'tech mask', r'tribal painted', r'emissive', r'bearsy', r'goldfish', r'\bgull\b',
        r'sea lion', r'painted tiger', r'tech demon', r'noh painted', r'contrast dragon', r'snake skull',
    ],
}
