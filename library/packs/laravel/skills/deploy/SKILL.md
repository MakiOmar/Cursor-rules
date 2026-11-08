---
name: deploy
description: Deploy or release this project to staging/production via git, with backups and smoke tests. Use when the user asks to deploy, release, go live, or sync data to a server.
---

# Deploy

Fill in the **Project values** once per project (copy this skill into the project's `.cursor/skills/deploy/`). Never write passwords or private keys here; the user supplies secrets per session.

## Project values

| Key | Value |
|-----|-------|
| SSH target | `{{user}}@{{host}}` (port `{{port}}`) |
| App root on server | `{{app_root}}` |
| Backend repo / branch | `{{backend_repo}}` / `{{branch}}` |
| Frontend repo / branch | `{{frontend_repo}}` / `{{branch}}` |
| Hosting type | `shared (git pull + build)` or `docker compose` |
| Backup folder on server | `{{backup_dir}}` (outside the web root) |
| Smoke-test URLs | `{{api_health_url}}`, `{{site_url}}`, `{{admin_login_url}}` |

## Order (stop and report at the first failure)

1. **Local:** tests and build pass; commit; push every repo involved (submodules first, then the parent repo).
2. **Pre-flight:** confirm the server can reach the database (e.g. `php artisan tinker --execute='DB::select("select 1");'`). If it fails, stop — credentials are fixed by the user, not over SSH.
3. **Backup:** dump the live database to `{{backup_dir}}/prod-backup-<timestamp>.sql`; archive uploaded files if they will be replaced.
4. **Data sync (only when the user asked):** confirm it overwrites live data, import, extract uploads, then rewrite local URLs in stored content (dry run → real run → dry run shows nothing left) and clear the cache.
5. **Backend:**
   `git pull && composer install --no-dev --optimize-autoloader --no-interaction && php artisan migrate --force && php artisan config:cache && php artisan route:cache && php artisan view:cache && php artisan storage:link --force`
6. **Frontend:** `git pull && npm ci`, then the type-check step (must report 0 errors) and the production build. Build-time `VITE_*` values come from the server's `.env.production`; rebuild when they change. Restart the Node process the way the host expects.
7. **Smoke test** every URL in Project values.

### Docker compose hosts

- Rebuild one service with `docker compose up -d --build --no-deps <service>`; without `--no-deps` Compose also recreates its dependencies.
- If containers run `artisan optimize` at boot, use `cache:clear` for data, not `optimize:clear`.
- `.env` is read at container start: recreate the container after changing it.

## Windows tooling

- Run remote commands from a temp script: `plink -batch -ssh -P <port> <user>@<host> -m script.sh` (keep the script outside the repo). Authenticate with Pageant or a key, never `-pw`.
- `mysqldump` in PowerShell: use long flags (`--host=127.0.0.1 --port=3306`); `-h127.0.0.1` gets mangled. Add `--single-transaction --no-tablespaces`, and dump cache/session tables with `--no-data`.
- If Windows `tar.exe` fails on large upload folders, use Git's `C:\Program Files\Git\usr\bin\tar.exe` and verify the file count with `-tf` before uploading.
- If `npm ci` hangs, find the busy install script from a second session: `ps -eo pid,etime,%cpu,args --sort=-%cpu | head -n 10`.

## Never

- Edit code on the server or upload locally built bundles.
- Leave dumps or credential files (e.g. a temp `my.cnf`) on the server.
- Run `migrate:fresh` or import over live data without step 3.
