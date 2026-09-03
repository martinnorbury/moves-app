# Moves (working name: "The Game") — v1.0

A private, two-player boundary-and-dare game for Martin and Jacki. Single-file
mobile web app, backed by Supabase. Completely separate from Lily's app —
different repo, different Supabase project, no shared data or credentials.

## How it works, in short

1. Each of you creates an account and pairs via a one-time invite code.
2. Each of you privately answers a boundary questionnaire — your partner never
   sees your individual answers, only the mutual result.
3. You send each other "moves" (dares) within your shared boundary.
4. Accepting and completing moves earns points and raises a shared Heat Meter,
   which unlocks rewards you've set up.

## 1. Create the Supabase project

1. Go to supabase.com → New project. Give it a name unrelated to Lily's app
   (e.g. a project named after this app's working/final name).
2. Once created, open **SQL Editor** → paste the entire contents of
   `supabase/schema.sql` → Run. This creates all tables, security policies,
   and functions, and seeds a small demonstration set of boundary questions.
3. Under **Settings → API**, copy:
   - `Project URL`
   - `anon public` key (never the `service_role` key)

## 2. Configure the app

Open `index.html` and replace the two placeholder values near the bottom:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

The anon key is safe to ship in client-side code — it only works because Row
Level Security policies (defined in `schema.sql`) restrict exactly what each
signed-in user can see and change. Never put the `service_role` key here or
anywhere in the repo.

## 3. Run it locally

No build step. Just open `index.html` in a browser, or serve the folder:

```bash
npx serve .
```

## 4. Deploy

Same pattern as Lily's app — push this repo and enable GitHub Pages
(Settings → Pages → deploy from the branch containing `index.html`), or any
other static host. There is no server component.

**Before your first commit:** double-check `index.html` doesn't contain a
`service_role` key, and that `.gitignore` excludes anything you don't intend
to publish (the anon key and project URL are fine to commit — they're public
by design).

## 5. Create the two accounts and pair them

1. Open the deployed app on your phone.
2. Tap **Create account**, enter a name, email, and password. Do this once
   for Martin and once for Jacki (two different emails).
3. On the first account, tap **Generate an invite code** — a 6-character
   code appears.
4. On the second account, enter that code under **Join with code**.
5. You're now a linked couple. Each of you should separately answer the
   boundary questionnaire under the **Boundaries** tab.

## 6. Install on an iPhone home screen

In Safari, open the deployed URL → Share → **Add to Home Screen**. The app
opens full-screen with a discreet name and icon on your lock/home screen.

## Environment variables / secrets

This app has no server-side component and no build step, so there are no
GitHub Actions secrets required for v1. The only "secret" (the anon key) is
intentionally public-safe and lives directly in `index.html`. If you later
add a CI/CD pipeline, keep the `service_role` key (if you ever need one) only
in GitHub Actions secrets — never in the repository itself.

## Backing up the database

Supabase → Database → Backups (or `pg_dump` against the connection string
under Settings → Database) gives you a full backup on demand. Do this
occasionally, particularly before applying a schema change.

## Applying future schema changes

Write new changes as additional `.sql` files (e.g. `supabase/0002_*.sql`)
rather than editing `schema.sql` in place, and run them in order via the SQL
Editor. This keeps a readable history of what changed and when, and matches
how you'd evolve Lily's app's schema.

## Security model, briefly

- Every table has Row Level Security enabled.
- Private boundary answers (`boundary_answers`) are readable only by the user
  who wrote them — there is no policy, anywhere, that lets a partner read the
  other's raw answers.
- The mutual boundary is computed by a `SECURITY DEFINER` database function
  (`compute_shared_boundary`) that reads both partners' private answers
  internally but returns only the joint result.
- Dares can only be inserted through `create_dare()`, which re-checks the
  live shared boundary server-side — the app can't be tricked into creating
  an out-of-boundary dare by editing values in the browser.
- All scoring timestamps and point calculations happen inside
  `complete_dare()` on the server, using the database's own clock — not the
  device's.
- Score corrections go through `score_adjustments`, a visible, additive
  ledger — no function silently rewrites history.

## What's deliberately not in v1

Push notifications, photo/video/voice storage, in-app AI generation, an
admin dashboard, analytics, multi-couple support, and anything not on the
agreed v1 scope. See `CHANGELOG.md` for what's next.

## Files

```
index.html            the entire app: markup, styling, and config
app.js                 all application logic
supabase/schema.sql    tables, RLS policies, and RPC functions
README.md              this file
CHANGELOG.md            version history
```
