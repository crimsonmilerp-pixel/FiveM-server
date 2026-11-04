# EUP conversion (how rp_eup was made)

`resources/[assets]/rp_eup` is the EUP Law & Order 8.3 pack turned into add-on clothing. This folder holds the tools and the lists that made it, so it can be rebuilt or extended. **Nothing here is uploaded to the server.** Claude runs these, not you.

## Where the source is

`eup-source/566105533_EUPLO8.3/` on Vinny's PC (git-ignored, about 1 GB): the official download from LCPDFR.com, unzipped. The clothes are inside three archive files in `content/x64/`:

| File | What's inside |
|---|---|
| `eup_componentpeds.rpf` (937 MB) | Clothing (shirts, pants, belts, vests, badges...) |
| `eup_componentpeds_p.rpf` (56 MB) | Hats and glasses |
| `script_txds.rpf` (1 MB) | Pictures for EUP's single-player menu (not used) |

The big one is too large to copy in one piece, so it was split with 7-Zip into 100 MB pieces (`eup_componentpeds.zip.001`...).

## Steps (Claude)

1. `python3 tool/rpf.py extract <file.rpf> <folder>` for each archive (they are unencrypted "OPEN" archives).
2. `tool/scan.py` groups the files into pieces. EUP was made for single player, so it *replaces* game clothes: each folder is named after the game collection it overwrites (`mp_m_freemode_01_male_heist`, ...).
3. `selection.json` lists every piece we ship, in order. **It is append-only**: piece numbers in `rp_eup` come from this order, and rank uniforms point at those numbers. To add pieces later, add them at the end of the right list, never in the middle, never remove.
   - Made by `tool/select_all.py`: every piece that ships its own model, minus blank 64x64 placeholder textures.
   - Left out: about 130 pieces that are only new paint on a normal game model (the model isn't in the pack), and the 11 first-person `_1` models.
4. `tool/build.py` copies and renames the files into the `rp_eup` collection (`mp_m_freemode_01_rp_eup^jbib_000_u.ydd` and so on) and writes the two `.ymt` files and two `.meta` files.
   - `tool/ymt.py` writes the `.ymt` (a GTA "Meta" resource with a `CPedVariationInfo`). It is a Python port of CodeWalker's MetaBuilder/ResourceBuilder and grzyClothTool's `BuildYMT` (both MIT licence).
5. `tool/verify.py <resource> rp_eup` checks that every piece in the `.ymt` has its model and the right number of textures, and that all files are valid resources.
6. `mapping.json` says where every new piece came from (`slot`, new number, source collection and number, texture letters).
7. Preview sheets: `tool/review.py` (every piece with all its versions, labelled with the new number) and `tool/zoom.py` (one piece, bigger). Used to pick the rank uniforms.

## Numbers in game

Inside the collection, piece numbers start at 0 for each slot (top 0, top 1...). The clothing menu shows a different, bigger number (all game clothes first, then `rp_eup` at the end), and that number changes when the game build changes. Our scripts use collection numbers (`SetPedCollectionComponentVariation(ped, 11, 'rp_eup', number, texture, 0)`), so they don't break on a new game build.

## Rank uniforms

The LSPD uniforms in the locker room are built from this pack. What each rank wears, the pictures, and how to change them: `uniforms.md` and `lookbook/`.

Tools added for that (Nov 4): `tool/ydd.py` and `tool/render.py` read the 3D models, `tool/fit.py` measures how one piece sits on another, `tool/uniforms.py` is the list of outfits, `tool/gen_config.py` writes them into illenium-appearance, `tool/lookbook*.py` and `tool/closeup.py` draw the pictures.
