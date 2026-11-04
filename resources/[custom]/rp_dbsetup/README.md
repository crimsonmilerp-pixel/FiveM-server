# rp_dbsetup: Database setup without a database tool

Scripts we download often come with a `.sql` file that has to be run on the database once (it creates their tables). This resource does that for us, so nobody needs HeidiSQL or phpMyAdmin.

## How it works

- The `.sql` files live in `sql/`, and `config.lua` lists them in order.
- On server start, every file that hasn't run yet runs once. The table `rp_db_migrations` remembers which ones are done.
- If a file has a `restart` resource (like `ps-mdt`), that resource is restarted right after, so it sees its new tables.
- The txAdmin console shows what happened, in lines starting with `[rp_dbsetup]`.
- If something fails, the file is **not** marked done. Fix the problem and restart; it runs again.

## Adding a new file

1. Put the `.sql` file in `sql/`, with the script name and version in the file name (for example `lb-phone_2.1.0.sql`).
2. Add a line to `migrations` in `config.lua`.
3. Never rename or reuse a file name that already ran.

## Start order

In `server.cfg`, `ensure rp_dbsetup` comes **before** the scripts whose tables it creates. On the very first start those scripts may print database errors for a few seconds, until rp_dbsetup restarts them.
