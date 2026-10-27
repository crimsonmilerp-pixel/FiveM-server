# rp_goals: Character Goals

Every new character commits to a **simple, actionable goal** right after they finish creating it. That goal is the reason they get moving instead of standing around.

## What it does

- **New characters:** once the clothing editor closes, a goal screen appears. Players can't skip it or walk around until they commit to a goal.
  1. A short explanation with good and bad example goals.
  2. A form: type of goal, the goal, why they want it, and their first step.
  3. A "Commit to this goal?" check, where they can choose **I commit** or **Edit**.
- **Existing characters without a goal** get the same screen the next time they spawn.
- **Every spawn after that:** a reminder pops up showing their goal.
- **`/goal`:** shows your goal. You can change it once every 7 days, and old goals are kept in history.
- **`/goals` (staff):** lists everyone online with their goal. Click a name for the full details. It's view-only, with no approvals.
- **No rewards or milestones.** The goal exists to give the character direction.

## Editing the words (Liam)

All text is in **`locales/en.json`**. Only change the words on the right side of each `:`.

- Keep every `%s`. The game fills those in with things like the goal text or a number.
- `\n` starts a new line. `**bold**` and `- lists` work in the big pop-ups.
- After editing, upload the file and type `restart rp_goals` in the txAdmin Live Console.

## Settings

**`config.lua`** controls answer lengths, the 7-day change cooldown, the spawn reminder, and timing. Each setting has a comment explaining it.

## Database

The tables are created automatically the first time the resource starts:

- `rp_character_goals`: each character's current goal
- `rp_character_goal_history`: past goals, saved whenever someone changes theirs

## Later

- When the server moves to a whitelist, the goal will also be part of the Discord application.
- Clean up goals when a character is deleted. This means adding our table to `characterDataTables` in `qbx_core/config/server.lua`.
