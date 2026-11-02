# rp_crews: Crews

Working with friends pays a bit more than working alone.

## How it works

- Type **`/crew`** to open the crew menu. Invite someone **standing nearby**, or **by ID** (their number on the scoreboard). Shortcut: **`/crew [ID]`** sends an invite straight away.
- The invited player gets a pop-up to join or decline. A crew holds up to **4** people.
- **Everyone still runs their own route** (their own garbage truck, cab, tow truck, or delivery truck).
- Every time a crew member finishes a task, they get **+10% for each crewmate who's also working the same job right now**, up to **+30%**. "Working right now" means that crewmate finished a task in the same job in the last 10 minutes.
- The bonus is paid to the bank right away with a short message ("Crew bonus: +$5").
- Jobs: **garbage, taxi, tow, trucker**. Taxi uses the real fare; the others use the average task value in `config.lua`.
- Crews end when people leave or log off, and on a server restart.

## Teaching players about crews

- Taking one of the crew jobs (at City Hall or by a boss) shows a tip about `/crew`.
- Anyone working alone gets a reminder about once an hour.
- The tour's City Hall step mentions crews.

## Needs

**rp_jobmoments**: it announces every finished task (`rp_jobmoments:server:taskDone`). If rp_jobmoments isn't running, there's no crew bonus.

## Settings and words

Numbers are in **`config.lua`** (bonus size, crew size, what counts as "working", reminder timing). All text is in **`locales/en.json`** for Liam. Keep every `%s`, and keep `%%` (it shows as a % sign).
