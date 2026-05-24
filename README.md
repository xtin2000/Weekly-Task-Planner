# The Week — Cloud Deployment Guide

Your personal weekly dashboard, hosted on GitHub Pages with a Supabase backend so you can access it from any device — laptop, iPhone, anywhere.

## What's in this package

```
dashboard-deploy/
├── index.html       — The dashboard app
├── manifest.json    — PWA manifest (lets you install on iPhone)
├── sw.js            — Service worker (offline support)
├── icon-192.png     — App icon (192×192)
├── icon-512.png     — App icon (512×512)
├── schema.sql       — Database schema for Supabase
└── README.md        — This file
```

## How it works (high level)

- **Frontend**: A single HTML file hosted on GitHub Pages (free, HTTPS).
- **Backend**: Supabase provides Postgres + auth. Your data is stored in one row keyed to your user ID.
- **Security**: Row-level security ensures only you can read or write your own data. All traffic is HTTPS.
- **Sync**: Every change auto-saves to Supabase (debounced 400ms). When you open the app on another device, it loads your latest state.

## Setup walkthrough

You'll do this once, then never touch it again. Total time: 15–20 minutes.

### Step 1 — Create a Supabase project

1. Go to https://supabase.com and sign up (free tier is fine).
2. Click **New Project**.
3. Pick a name (e.g. "weekly-dashboard"), a strong database password (save it in a password manager), and a region close to you (US West for LA).
4. Wait ~2 minutes for the project to provision.

### Step 2 — Run the schema

1. In your Supabase project dashboard, click the **SQL Editor** icon in the left sidebar.
2. Click **New query**.
3. Copy the entire contents of `schema.sql` into the editor.
4. Click **Run**.

You should see "Success. No rows returned." This creates the `dashboard_state` table and locks down access with row-level security.

### Step 3 — (Optional) Disable email confirmation for faster signup

By default, Supabase makes you click a confirmation link in your email before you can sign in. Since you're the only user, you can disable this:

1. In Supabase, go to **Authentication** → **Providers** → **Email**.
2. Turn off **Confirm email**.
3. Click **Save**.

If you leave it on, your first signup will send you a confirmation email — click the link, then come back and sign in.

### Step 4 — Get your project URL and anon key

1. In Supabase, go to **Project Settings** (gear icon) → **API**.
2. Copy two values:
   - **Project URL** (something like `https://abcdefgh.supabase.co`)
   - **anon / public key** (a long string starting with `eyJ...`)

**Note about the anon key**: This key is meant to be exposed in the frontend. It identifies your project but does not grant database access on its own. Access is controlled by the row-level security policies you ran in step 2. This is the standard Supabase pattern.

### Step 5 — Paste your values into `index.html`

Open `index.html` in any editor. Near the top of the `<script>` section, find:

```js
const SUPABASE_URL = "YOUR_SUPABASE_URL_HERE";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY_HERE";
```

Replace with the values you copied. Save the file.

### Step 6 — Deploy to GitHub Pages

In a terminal, from the `dashboard-deploy/` directory:

```bash
git init
git add .
git commit -m "Initial dashboard"
git branch -M main

# Create a new GitHub repo (replace YOUR-USERNAME and REPO-NAME)
# Either do this on github.com, or with the gh CLI:
gh repo create REPO-NAME --public --source=. --remote=origin --push
```

If you don't have `gh` (GitHub CLI), create the repo manually at https://github.com/new, then:

```bash
git remote add origin https://github.com/YOUR-USERNAME/REPO-NAME.git
git push -u origin main
```

Then enable GitHub Pages:

1. Go to your repo on github.com → **Settings** → **Pages**.
2. Under **Source**, pick **Deploy from a branch**.
3. Select **main** branch and **/ (root)** folder. Click **Save**.
4. Wait 1–2 minutes. Your site will be at `https://YOUR-USERNAME.github.io/REPO-NAME/`.

### Step 7 — First sign-in

1. Open the URL on your laptop.
2. The auth screen appears. Click **Sign up**, enter your email and a strong password (8+ chars).
3. If you disabled email confirmation in step 3, you'll be logged in immediately. Otherwise, check your email and click the link.
4. The dashboard appears. Add a task to test that it saves (you'll see "Saving…" then "Synced" in the top right).

### Step 8 — Install on iPhone

1. Open the same URL in Safari on your iPhone.
2. Tap the **Share** icon (square with arrow).
3. Scroll down and tap **Add to Home Screen**.
4. Tap **Add**.
5. The app appears on your home screen with its own icon. Open it — it runs full-screen like a native app.
6. Sign in with the same email + password.

Now you can add a task on your iPhone, switch to your laptop, refresh, and see it. Real-time sync.

## Importing your existing data

If you already filled in tasks in the Claude artifact version:

1. Open the Claude artifact, click **Export data** in the footer. A JSON file downloads.
2. Open your deployed GitHub Pages URL, sign in.
3. Click **Import data**, select the JSON file, confirm.

All your tasks, completions, urgent flags, etc. carry over.

## Updating later

When we make further changes:

1. **Always export first** from your live deployed version (footer → Export data).
2. Replace `index.html` (and any other files) with the new version.
3. Paste your `SUPABASE_URL` and `SUPABASE_ANON_KEY` back in (they're in the same spot near the top of the script).
4. Commit and push:
   ```bash
   git add .
   git commit -m "Update dashboard"
   git push
   ```
5. GitHub Pages will redeploy in 1–2 minutes.
6. If the data structure didn't change, your data is still in Supabase and just loads. If it did change, import the JSON you exported.

## Security notes

- **HTTPS everywhere**: GitHub Pages serves over HTTPS automatically. Supabase enforces HTTPS on its API.
- **Row-level security**: The SQL in `schema.sql` enforces that even with your anon key, no one can read or write rows that don't belong to their user ID. This is the cornerstone of Supabase security.
- **Password**: Pick a strong, unique password. Supabase hashes passwords with bcrypt by default; they never see your plaintext.
- **Anon key safety**: The anon key in your frontend HTML is visible to anyone who views source. This is by design. Security is enforced by RLS on the database, not by hiding the key.
- **Device security**: If your iPhone is unlocked, anyone holding it can see your tasks. Use Face ID / passcode. The browser remembers your Supabase session (so you don't sign in every time), which is convenient but means device-level security matters.
- **Backups**: Keep using the Export feature periodically. The JSON file is your insurance policy if anything ever goes wrong with the database.

## What you control

- **Reset all data**: Wipes your dashboard. Doesn't delete your Supabase account or row, just clears the data.
- **Sign out**: Ends the session on this device. Other devices stay signed in.
- **Delete account**: To fully delete, do this from the Supabase dashboard: **Authentication** → **Users** → find yourself → delete. Your row in `dashboard_state` is auto-deleted via the foreign key cascade.

## Costs

Free, as long as you stay within Supabase's generous free tier limits, which a single user with task data will never approach:
- 500 MB database storage (you'll use kilobytes)
- 50,000 monthly active users (you're one)
- 2 GB bandwidth (you'll use megabytes)

GitHub Pages is free for public repos. If you want the repo private, you'd need GitHub Pro ($4/mo) — but the repo doesn't contain any secrets worth hiding, just your URL/anon key which are designed to be public.

## Troubleshooting

- **"Supabase not configured"** on the auth screen → you didn't paste the URL or anon key into `index.html`.
- **"Invalid login credentials"** → wrong email/password, or you haven't confirmed your email if confirmation is still enabled.
- **Tasks not saving** → check the sync status in the top right. If "Save failed", open browser console (F12) for the error. Most common cause: RLS policies not set up, meaning the schema SQL didn't run completely.
- **Different data on different devices** → make sure you're signed in with the same account. Sign out and back in to refresh.
- **iPhone install: no "Add to Home Screen" option** → must be Safari, not Chrome on iOS. Apple restricts this to Safari.

## Replacing the placeholder icons

The `icon-192.png` and `icon-512.png` files are simple placeholders. Replace them with whatever icon you want — keep the same filenames and sizes (192×192 and 512×512 PNG). After replacing, commit and push.
