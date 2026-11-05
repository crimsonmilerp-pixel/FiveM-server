# rp_clothing_images

Pictures of every clothing item, for our clothing menus (character creator, clothing stores, barber).
The menus live in `illenium-appearance/web/dist` and load the pictures from this resource's `img/` folder.
Without pictures the menus still work: they show item numbers instead.

## Making the pictures (staff, on the dev server)

1. Join the server with nobody else needing you for half an hour. Make sure `screencapture` is running.
2. Type `/clothingphotos` in chat. The screen shows a mannequin on a green floor; the tool dresses it in every
   item, one by one, for the man and then the woman. It takes about half an hour. **Keep the game window in front
   and don't touch the mouse or keyboard** (alt-tabbing can pause the screenshots).
   - Progress shows in the F8 console (`[clothingphotos] male_c11: 150/512`).
   - `clothingphotos stop` in the F8 console stops after the current picture.
   - Redo one slot: `/clothingphotos male c11` (slot names are in `config.lua`).
   - Quick test (about 3 minutes): `/clothingphotos male all 6` takes only the first 6 items of every slot.
3. When it says `finished`, restart this resource in txAdmin (`restart rp_clothing_images`) so players get the new
   pictures. Then open a clothing store and check them.
4. Download the `img/` folder from the server (WinSCP: server → PC, into `resources/[custom]/rp_clothing_images/img`)
   and commit it, so GitHub has the pictures too.

The F8 console also prints an "arms report": how many tops the game can match arms to automatically. Send it to Claude.

For checking the camera, each slot also saves three small raw photos in `img/debug/` (bare mannequin, empty scene,
first item). They are never sent to players.

## How it works

- The player is moved into their own empty world (no traffic, no other players), at the airport, with frozen
  sunny weather. A big green ball behind the mannequin and a flat green one under its feet act as a green screen
  (the flat one also hides shadows on the ground). The mannequin is held perfectly still.
- For each slot it first photographs the bare mannequin (5 times, to see if anything moves by itself) and the
  empty scene. Earrings are photographed from both sides, and each one keeps the side where it shows best. An item is whatever changed compared with the bare mannequin, so the background, the floor and the
  head are removed. Hair, hats, glasses, masks and earrings keep the head, so they look worn.
- Items that show nothing (like "no mask") are listed as empty; the menus fold them into one "None" choice.
- Loose bits away from the item (like its shadow on the ground) are dropped, so the picture is zoomed on the item.
- Items that show the game's bright pink "missing texture" are listed as broken and hidden from players (staff still see them).
- Pictures are 128 px and packed into one sheet per slot (`img/male_c11.webp`); `img/index.json` says where each
  item is. Police uniforms (the `rp_eup` pack) are skipped.

## Files

| File | What |
|---|---|
| `config.lua` | Camera angle and zoom per slot, where the mannequin stands, picture size |
| `client.lua` | The photo session (staff only) |
| `html/` | Invisible page that cuts the items out of the screenshots and builds the sheets |
| `server.js` | `/clothingphotos` (needs the `admin` ACE), saves the sheets into `img/` |
| `img/` | The pictures and `index.json` |
