# Core changes log

Any edit to a resource we didn't write (Qbox, ox_*, npwd, etc.) gets logged here. When we update that resource, we'll need to redo these changes.

| Date | Resource | File | What changed | Why | Who |
|---|---|---|---|---|---|
| 2026-10-26 | qbx_core | `shared/jobs.lua` | `unemployed` grade 0 `payment` 10 → 0 | No free paycheck for idling (Pillar B). Qbox skips paychecks of 0. | Claude |
| 2026-10-26 | qbx_core | `config/client.lua` | `discord.enabled` true → false | The Discord status showed Qbox's icon, app, and Discord button. Re-enable with our own Discord app ID, art, and invite once the server is named. | Claude |
