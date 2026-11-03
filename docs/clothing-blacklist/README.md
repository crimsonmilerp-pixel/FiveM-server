# Clothing blacklist (Pillar C)

The clothing menu (illenium-appearance) hides costume, holiday and lingerie items so the city looks like real people live in it. This folder holds the rules and the script that build the hidden list. **Nothing here is uploaded to the server.**

## What's hidden

| Group | What | Who can see it |
|---|---|---|
| `clothing.festive` | Christmas (Santa, elves, reindeer, ugly sweaters), Valentine's, Thanksgiving turkey, New Year's party gear | Nobody, until staff switch it on for the season |
| `clothing.halloween` | Horror and monster masks, pumpkin tees | Nobody, until staff switch it on in October |
| `clothing.costume` | Cartoon characters, food mascots, sci-fi, glowing/LED items, apocalypse armor, joke hats | Nobody |
| `clothing.racy` | Lingerie (lace panties, stockings on their own) | Nobody |

**Kept on purpose:** swimwear, boxers, bustiers, and masks a real person could buy: balaclavas, ski masks, bandanas, gaiters, gas and tactical masks, hockey masks, and party-store rubber masks (pig, ape, skull, clown, president, animal heads).

`report.md` lists every hidden item by its number (the same number the clothing menu shows).

## Switching holidays on and off

In `permissions.cfg`, remove the `#` in front of the line and restart the server:

```
add_ace builtin.everyone clothing.festive allow
add_ace builtin.everyone clothing.halloween allow
```

Or paste the line into the **txAdmin live console** to switch it on right away. To switch it off live, paste the same line with `remove_ace` instead of `add_ace`.

## Items with no name

About 1,100 items have no in-game name, so the rules couldn't check them (the bottom of `report.md` lists their numbers). If you spot a costume piece in the clothing menu, note the slot (Mask, Top, Hat...) and the number, and Claude adds it.

## Rebuilding (Claude does this)

1. Get the clothing names list: `git clone https://github.com/root-cause/v-clothingnames` (game build 3889 as of Jul 2026).
2. Edit `rules.py` (each rule is a pattern matched against an item's name).
3. `python3 build.py <v-clothingnames folder> <path to illenium-appearance/shared/blacklist.lua> report.md`
4. Upload `blacklist.lua` and restart `illenium-appearance`.
