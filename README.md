# Moves (working name: "The Game")

A private, two-player boundary-and-dare game for Martin and Jacki. Single-file
mobile web app, backed by Supabase. Completely separate from Lily's app —
different repo, different Supabase project, no shared data or credentials.

Current version and full change history: see `CHANGELOG.md`, or tap the
version number in the app itself.

## How it works, in short

1. Each of you creates an account, picks a colour theme, and pairs via a
   one-time invite code.
2. Under **Boundaries**, you build your own set of headings (Teasing &
   Dirty Talk, Touch & Sensation, Positions & Core Acts, Dominance &
   Surrender, Roleplay & Fantasy, Risk, Public & Exhibition, or whatever
   else you add) and
   your own cards under each one — a title, a description, and optionally a
   private photo. Add them one at a time, or import many at once from a CSV.
3. Each of you privately answers each card: Full Spark, Warming Up, Blushing
   Yes, Just For You, or Cold Card. Your partner never sees your individual
   answers — only the mutual result.
4. You send each other "moves" (dares) within your shared boundary.
5. Accepting and completing moves earns points and raises a shared Heat
   Meter, which unlocks rewards you've set up.

## Current live setup

The Supabase project and database are already built and live — you don't
need to redo the steps below unless you're rebuilding from scratch (e.g.
disaster recovery, or setting this up somewhere new). Keeping them here for
that reason.

### 1. Create the Supabase project

1. Go to supabase.com → New project. Give it a name unrelated to Lily's app.
2. Open **SQL Editor** → paste the entire contents of `supabase/schema.sql`
   → Run. This creates every table, security policy, function, the private
   image storage bucket, and the starter set of headings.
3. Under **Settings → API**, copy the `Project URL` and the `anon public`
   key (never the `service_role` key).

### 2. Configure the app

Open `index.html` and find the two placeholder values near the bottom (in
the same `<script>` block as everything else — there's only one file):

```js
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

The anon key is safe to ship in client-side code — it only works because Row
Level Security policies (defined in `schema.sql`) restrict exactly what each
signed-in user can see and change. Never put the `service_role` key here or
anywhere in the repo.

### 3. Deploy

Push the repo and enable GitHub Pages (Settings → Pages → deploy from the
branch containing `index.html`). The repo needs to be **public** for Pages
to work on a free GitHub account — this is fine here specifically because
the anon key is designed to be public; your actual data stays protected by
Row Level Security regardless of who can see the source code.

## Adding your own content

- **One card at a time:** open a heading in the Boundaries tab → "+ Add a
  card here" → fill in the title, description, pick a suggested intensity
  and who it suits, optionally attach a photo.
- **Many at once via CSV:** Boundaries tab → "Import from CSV". Columns:
  `category, title, explanation, max_intensity, suitable_for`.
  - `max_intensity` must be one of: `tease`, `risque`, `bold`, `wild`
  - `suitable_for` must be one of: `apart`, `together`, `either`, `reunion`
    (defaults to `either` if left blank)
  - Headings that don't exist yet are created automatically
  - Column headers aren't case-sensitive, and a few alternate names are
    accepted (`heading` for `category`, `name` for `title`, `description`
    for `explanation`, `intensity` for `max_intensity`, `type` for
    `suitable_for`)
  - Images aren't part of CSV import — add those individually afterwards
- **New headings:** "Add a new heading" on the Boundaries tab, or just use
  a heading name in a CSV import that doesn't exist yet.

Photos you attach are stored in a private Supabase storage bucket — not
public, not visible to anyone outside your couple, enforced at the storage
level rather than just hidden in the interface.

## Create the two accounts and pair them

1. Open the deployed app on your phone.
2. Tap **Create account**, enter a name, pick a theme, and set an email and
   password. Do this once for Martin and once for Jacki.
3. On the first account, tap **Generate an invite code** — a 6-character
   code appears, and stays visible on a "waiting on your partner" screen
   until it's used (regenerate it from that same screen if it expires).
4. On the second account, enter that code under "Join with code."

## Install on an iPhone home screen

In Safari, open the deployed URL → Share → **Add to Home Screen**. The app
opens full-screen with a discreet name and icon on your lock/home screen.

## Backing up the database

Supabase → Database → Backups (or `pg_dump` against the connection string
under Settings → Database) gives you a full backup on demand. Do this
occasionally, particularly before applying a schema change.

## Applying future schema changes

Write new changes as additional `.sql` files rather than editing
`schema.sql` in place, run them via the SQL Editor, and fold the change into
`schema.sql` afterwards so it stays an accurate single reference of the
live state — that's what happened here: several rounds of fixes and new
features were applied directly, then consolidated back into this file.

## Security model, briefly

- Every table has Row Level Security enabled.
- Private boundary answers (`boundary_answers`) are readable only by the
  user who wrote them — there is no policy, anywhere, that lets a partner
  read the other's raw answers.
- The mutual boundary is computed by a `SECURITY DEFINER` database function
  (`compute_shared_boundary`) that reads both partners' private answers
  internally but returns only the joint result.
- Boundary cards (`boundary_questions`) and dares can only be inserted
  through dedicated functions (`add_boundary_question`, `create_dare`),
  which enforce couple ownership and the live shared boundary server-side —
  the app can't be tricked into creating something out-of-boundary by
  editing values in the browser.
- Photo uploads are checked against your couple's own storage folder —
  policies compare the file path's folder to your couple ID, so one
  couple's images are never reachable by another.
- All scoring timestamps and point calculations happen inside
  `complete_dare()` on the server, using the database's own clock — not the
  device's.
- **Important Supabase-specific gotcha, found the hard way:** Supabase
  grants EXECUTE on every new function directly to the `anon` role
  (unauthenticated visitors) by default, separately from the general
  `PUBLIC` grant. Revoking from `PUBLIC` alone does **not** remove this —
  `anon` needs revoking explicitly too, every time. Every function in
  `schema.sql` does this correctly, and was verified with a direct
  database query rather than trusting the automated linter's first pass.
  If you ever add a new function by hand, follow the same pattern and
  verify with:
  ```sql
  select has_function_privilege('anon', 'your_function_name'::regproc, 'EXECUTE');
  ```

## What's deliberately not in v1

Push notifications, video/voice storage, in-app AI generation, an admin
dashboard, analytics, multi-couple support, and anything not on the agreed
v1 scope. See `CHANGELOG.md` for what's next.

## Files

```
index.html                      the entire website: markup, styling, config, and all logic
supabase/schema.sql              current database setup — accurate reference copy, already applied
boundary-cards-template.csv       starter template for bulk-importing your own cards
dare-library-template.csv         starter template for bulk-importing dare library entries
forfeit-library-template.csv      starter template for bulk-importing forfeits
README.md                        this file (documentation only — not part of the website)
CHANGELOG.md                      version history (the app's own version screen reads this live)
```

Only `index.html` needs to be live on the web for the app to work.
`schema.sql` is kept as an accurate record of the database, not something
that needs re-running unless you're rebuilding from scratch.
