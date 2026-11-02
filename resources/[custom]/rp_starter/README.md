# rp_starter: Starter Area

Everything a brand-new character goes through after making their goal.

## The flow

1. **Arrive** at the downtown bus station (set in `qbx_core/config/shared.lua` → `defaultSpawn`). There's no free apartment anymore.
2. **Clothing**, then the **goal** screen (rp_goals).
3. The **tour** starts. Each step shows a notification, a GPS route, and a map marker:
   1. Talk to the **Fresh Start volunteer**.
   2. Pick a **free starter vehicle**: Asea (sedan), Landstalker (SUV), PCJ-600 (motorcycle), Chino (old muscle), or Bobcat XL (truck). It spawns with about half a tank and you're put in the driver's seat.
   3. Check out the **kiosk** (water, snacks, bandages, painkillers, repair kit at 24/7 prices).
   4. Drive to the **Fleeca bank** on Legion Square.
   5. Stop at the **gas station** on Strawberry Ave.
   6. Visit **City Hall** (jobs and IDs).
   7. A final screen shows **your goal's first step**.

Progress is saved, so logging out mid-tour picks up where you left off.

## Rules

- **One free vehicle per character.** It **can't be sold or traded**: the used car lot, selling back to the dealer, and `/transfervehicle` all refuse it.
- **The first character on an account has to take the tour.** Later characters can type **`/skiptutorial`**. Staff can always skip.
- **`/tutorial`** shows your current step again (and resets the GPS).
- Characters made before this was installed don't get a tour.
- The bus station always has a map marker, so new players can find their way back to the volunteer.

## Moving things

The volunteer, the kiosk, and the vehicle spawn spot are in **`config.lua`**. To move one, stand on the spot in game, type **`/buyerhere`** (it copies your position), and paste it over that `coords = vec4(...)` line. Then upload the file and type `restart rp_starter`.

## Editing the words (Liam)

All text is in **`locales/en.json`**: the volunteer's welcome, the vehicle descriptions, and every tour step. **It's placeholder text** until Liam writes the arrival story. Only change the words on the right side, and keep every `%s`.

## Database

`rp_starter_progress` (created automatically): each character's tour step, and their starter vehicle.
