# FiveM Server (name TBD)

The complete server: Qbox framework, every resource, and our config. GitHub is the **single source of truth**. If it isn't in this repo, it doesn't exist.

- **Plan and decisions:** `docs/design-bible.md`
- **Our own code:** `resources/[custom]/`
- **Hosting:** Nodecraft Pro 6 GB, managed through txAdmin
- **Local copy:** `C:\Users\mrgri\FiveM\server` on Vinny's PC

---

## How the server is laid out

| On the server (FTP root `/`) | In this repo? | Notes |
|---|---|---|
| `resources/` | ✅ | All scripts. Ours go in `resources/[custom]/`. |
| `server.cfg`, `permissions.cfg`, `ox.cfg`, `voice.cfg`, `misc.cfg` | ✅ | Main config. `server.cfg` loads the others. |
| `secrets.cfg` | ❌ never | Database password and any future keys or webhooks. |
| `nodecraft_config.cfg` | ❌ never | Written by Nodecraft from its panel: license key, max players, startup settings. |
| `cache/`, `FXServer/`, `servers/` | ❌ | Temporary files, the server program, and txAdmin's own data. |

The server's name, description, and tags are set in the **Cfx.re Portal** (portal.cfx.re → Servers), not in `server.cfg`.

---

## Tools (all free)

| Tool | What it's for |
|---|---|
| **VS Code** | Reading and editing code. Install the recommended extension when it asks. |
| **GitHub Desktop** | Saving and syncing changes to GitHub without typing commands. |
| **WinSCP** | Uploading files to Nodecraft. Use File protocol **FTP**, Encryption **TLS/SSL Explicit**, port **121**, and the temporary login from the Nodecraft **Overview** page. |

---

## Everyday workflow

1. **Pull** the latest in GitHub Desktop before starting.
2. **Edit** in VS Code, or Claude writes the files into this folder.
3. **Review and commit** in GitHub Desktop with a clear message, for example `goals: add goal input on first spawn`, then **Push**.
4. **Upload** only the changed files or folders to the server with WinSCP.
5. **Restart only that resource.** Use txAdmin → Resources, or type `restart rp_goals` in the Live Console. Config (`.cfg`) changes need a full server restart.
6. **If it breaks:** in GitHub Desktop, right-click the commit, choose *Revert*, re-upload, and restart.

---

## House rules

- **Never commit secrets.** Before every commit, scan the change list in GitHub Desktop. If you see `mysql://`, `cfxk_`, `webhook`, or `password`, stop.
- **Changes made on the server get committed the same day.** If you (or James) edit something in txAdmin's CFG Editor or the Nodecraft file manager, download that file and commit it.
- **Don't edit Qbox or other downloaded resources directly.** Build our features as separate resources in `[custom]`, so updates never wipe our work. If a core change is unavoidable, log it in `docs/core-changes.md`.
- **Player-facing text goes in `locales/en.json`, not in code,** so Liam can edit it.
