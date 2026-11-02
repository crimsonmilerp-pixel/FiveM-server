# rp_jobmarkers: Work Markers

Qbox only shows a job's depot on the map **after** you take that job. This adds a **"Work: …" marker for every job depot that everyone can see**, so new players know where the work is before signing up at City Hall.

- Garbage depot, taxi depot, tow yard, and trucker shed.
- Your own job's marker is hidden here (that job's script already shows it), so markers don't double up.
- Walk up to a depot without that job and you get a hint: sign up at City Hall first.
- Markers are "short range": they're always on the pause-menu map, and show on the minimap when you're near.

**Settings:** `config.lua` (spots, icons, colors). **Words:** `locales/en.json`.

Add a job by adding a line to `markers` in `config.lua` and its name under `marker` and `job` in `locales/en.json`.
