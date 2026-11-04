# rp_eup: police uniforms (EUP)

The **Emergency Uniforms Pack: Law & Order 8.3** by the EUP Team, converted into **add-on clothing**. It adds a new clothing collection called `rp_eup` and **replaces nothing**: every normal GTA shirt, hat and pair of shoes stays exactly as it was.

- 477 pieces (255 for men, 222 for women) with 2,920 colour and agency versions: shirts, jackets, pants, duty belts, vests, badges, rank insignia, hats and more, for LSPD and the other San Andreas agencies.
- Only police see these pieces in the clothing menu. Everyone else never sees them (the lock is in illenium-appearance, see `docs/core-changes.md`).
- Staff with the `clothing.uniforms` permission see them too (for testing and events).

## Testing it

In game, type **`/eupcheck`**. A man's character should show **255 pieces**: masks 3, pants 14, belts and bags 34, shoes 3, accessories 18, undershirts 51, vests 34, badges and insignia 17, tops 53, hats 24, glasses 4. A woman's character shows **222**. If everything is **0**, the clothes didn't load: check the txAdmin console for `rp_eup` errors and tell Claude.

## Size and the 10 player rule

- Players download about **825 MB** the first time they join (after that it's cached).
- Custom clothing only works on servers with **10 slots or fewer** unless the server owner has Cfx.re Element Club Argentum. Decide before launch (see the design bible).

## What's not included

About 130 EUP items are only new paint for a normal GTA clothing shape (the shape itself lives in the game). Those can't be turned into add-ons without copying the game's own models, so they were left out. First-person versions of 11 jackets were also left out (the normal version shows in first person).

## Files

| Path | What it is |
|---|---|
| `stream/` | The clothes (about 3,400 files). **Not on GitHub** (too big): keep the folder on your PC and upload it with WinSCP. |
| `stream/mp_m_freemode_01_rp_eup.ymt`, `..._f_...ymt` | The list of pieces and how many versions each has. Generated, never edit. |
| `*.meta` | Tells the game the `rp_eup` collection exists. |
| `client/check.lua` | The `/eupcheck` command. |

## Rebuilding

Never rename, reorder or remove pieces by hand: rank uniforms point at piece numbers. Claude rebuilds the pack from `eup-source/` with the tools in `docs/eup/`, and only ever **adds** pieces at the end so existing numbers never move.

## Credits and licence

EUP: Law & Order is made by the **EUP Team** (Alex_Ashfold, PieRGud, Nacho, Alex Braun, Will) with thanks to their contributors. Original: https://www.lcpdfr.com/files/file/8151-emergency-uniforms-pack/

EUP is shared under the Creative Commons **Attribution-NonCommercial-ShareAlike 4.0** licence (https://creativecommons.org/licenses/by-nc-sa/4.0/). This converted version keeps that licence: credit the EUP Team, **never sell these uniforms or put them behind a paywall**, and share any changes under the same licence. Converted for our server by Claude (Nov 2026): files renamed into the `rp_eup` collection, new `.ymt`/`.meta` files written, blank placeholder textures removed. Nothing else was changed.
