# Render Deployment Guide (Backend + PostgreSQL)

This guide deploys the FastAPI backend (`backend/`) and its PostgreSQL database to
[Render](https://render.com) using Render's native **Python** runtime (no Docker).

```
Flutter app ──HTTPS──▶ Render Web Service (FastAPI) ──internal network──▶ Render PostgreSQL
                              ▲
GitHub Actions keep-alive ────┘  (pings /health every 10 min)
```

---

## 0. Before you start

- The code is pushed to GitHub (`main` branch).
- You have a Render account, signed in with GitHub.
- Pick **one region** (e.g. Singapore) and use it for **both** the database and the web
  service. They can only talk over Render's internal network if they are in the same region.

---

## 1. Create the PostgreSQL database

1. Render Dashboard → **New +** → **Postgres**.
2. Fill in:

   | Field | Value |
   |---|---|
   | Name | `blood-donor-db` |
   | Database | `blood_donation_db` |
   | User | `blood_admin` (any name) |
   | Region | your chosen region |
   | PostgreSQL Version | 17 (or the latest offered) |
   | Plan | Free (or paid) |

3. Click **Create Database** and wait until the status is **Available**.
4. Open the database → **Info** → **Connections**. Keep this page open; you need:
   **Hostname** (internal), **Port**, **Database**, **Username**, **Password**.

> **Free plan note:** Render's free Postgres expires 30 days after creation (Render
> emails you before). Upgrade to a paid plan before then, or your data is deleted.

---

## 2. Create the Web Service

1. Render Dashboard → **New +** → **Web Service**.
2. Connect the GitHub repository `blood-donor-management-system`.
3. Fill in:

   | Field | Value |
   |---|---|
   | Name | `blood-donor-api` (becomes `https://blood-donor-api.onrender.com`) |
   | Language | **Python 3** |
   | Branch | `main` |
   | Region | **same region as the database** |
   | Root Directory | `backend` |
   | Build Command | `pip install -r requirements.txt` |
   | Start Command | `python -m src.db.script.migrate && uvicorn main:app --host 0.0.0.0 --port $PORT` |
   | Instance Type | Free (or paid) |

   The start command runs any pending database migrations first, then starts the API.
   Migrations are tracked in the `migrations` table, so re-running them on every start
   is safe: already-applied files are skipped.

4. Scroll to **Environment Variables** and add:

   | Key | Value |
   |---|---|
   | `PYTHON_VERSION` | `3.12.8` |
   | `DB_HOST` | Hostname from step 1 (internal, looks like `dpg-xxxxxxxx-a`) |
   | `DB_PORT` | `5432` |
   | `DB_NAME` | `blood_donation_db` |
   | `DB_USER` | Username from step 1 |
   | `DB_PASSWORD` | Password from step 1 |
   | `JWT_SECRET_KEY` | a long random string (see below) |
   | `JWT_ALGORITHM` | `HS256` |
   | `JWT_EXPIRE_MINUTES` | `60` |

   Generate a strong `JWT_SECRET_KEY` on your computer:

   ```bash
   python3 -c "import secrets; print(secrets.token_urlsafe(48))"
   ```

   Never reuse the example value from `.env.example`, and never commit the real one.

5. Open **Advanced** → set **Health Check Path** to `/health`.
6. Click **Create Web Service**. Render builds and deploys. Watch the **Logs** tab.

A successful first deploy shows something like:

```
RUN   001_create_users.sql
DONE  001_create_users.sql
...
All migrations completed.
PostgreSQL database connected successfully!
Uvicorn running on http://0.0.0.0:10000
```

---

## 3. Check that it works

Replace the URL with your own service URL.

```bash
curl https://blood-donor-api.onrender.com/health
```

Expected: `{"status":"ok","database":"connected"}`

Open the interactive API docs in a browser to try the endpoints:
`https://blood-donor-api.onrender.com/docs`

Quick end-to-end check from the docs page:
1. `POST /api/users/register` → create a user.
2. `POST /api/users/login` → copy `access_token`.
3. Click **Authorize** (top right), paste the token.
4. `GET /api/users/profile` → returns your user.

---

## 4. Point the Android app at Render

In `frontend/lib/config/api_config.dart`:

```dart
static const String baseUrl = "https://blood-donor-api.onrender.com";
```

No trailing slash. Then rebuild the app. See [ANDROID_BUILD.md](ANDROID_BUILD.md).

---

## 5. Keep the free instance awake

Free web services go to sleep after ~15 minutes without traffic. The next request then
waits ~30–60 seconds while it wakes up, which can make the app time out.

The repo includes a GitHub Actions job, `.github/workflows/keep-alive.yml`, that pings
`/health` every 10 minutes. To turn it on:

1. GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
   → **New repository variable**.
2. Name: `BACKEND_URL`, Value: `https://blood-donor-api.onrender.com` (no trailing slash).
3. **Actions** tab → **Keep backend awake** → **Run workflow** once to test it.

Notes:
- GitHub only runs scheduled jobs from the default branch (`main`), and may delay them by a
  few minutes.
- GitHub disables scheduled jobs after 60 days without commits. Re-enable them in the
  Actions tab, or push a commit.
- Alternatives that need nothing in the repo: [cron-job.org](https://cron-job.org) or
  [UptimeRobot](https://uptimerobot.com), monitoring the same `/health` URL.
- One always-awake free service uses ~744 hours/month, within Render's 750 free hours.
  A second free service kept awake would exceed it.

---

## 6. Updating the backend

Render auto-deploys on every push to `main`:

```bash
git push origin main
```

New migration? Add the next numbered file to `backend/src/db/migrations/`
(e.g. `006_add_something.sql`). It runs automatically on the next deploy.
**Never edit a migration that has already run in production.** Add a new one instead.

To deploy manually: service page → **Manual Deploy** → **Deploy latest commit**.

---

## 7. Connecting to the production database (optional)

Use the **External Database URL** / **PSQL Command** from the database's **Connections**
section (the internal hostname only works inside Render):

```bash
psql "postgresql://USER:PASSWORD@EXTERNAL_HOST/blood_donation_db?sslmode=require"
```

Useful checks:

```sql
SELECT * FROM migrations ORDER BY id;
SELECT id, first_name, email, blood_group FROM users LIMIT 10;
```

---

## 8. Troubleshooting

| Symptom in Render logs | Cause / fix |
|---|---|
| `ModuleNotFoundError: No module named 'main'` or `'src'` | **Root Directory** is not `backend`. |
| `could not translate host name` / `Connection refused` | Wrong `DB_HOST`, or DB and service are in **different regions**. Use the *internal* hostname in the same region. |
| `password authentication failed` | `DB_USER` / `DB_PASSWORD` don't match the database's Connections page. |
| `ValueError: invalid literal for int()` on startup | `DB_PORT` or `JWT_EXPIRE_MINUTES` is empty or not a number. |
| `No open ports detected` | Start command doesn't use `--host 0.0.0.0 --port $PORT`. |
| Build fails compiling `asyncpg` | `PYTHON_VERSION` is missing or too new. Use `3.12.8`. |
| `401 Invalid or expired token` after redeploy | `JWT_SECRET_KEY` changed. Users need to log in again. |
| App times out on the first request | The service was asleep. Set up step 5, or wait and retry. |
| Database gone after a month | Free Postgres expired. See the note in step 1. |
