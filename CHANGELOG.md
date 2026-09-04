# Changelog

## 1.5.0 — list view for cards

- Added a "List view" option inside each heading, alongside the original
  one-at-a-time card view — a searchable, scrollable list showing every
  card's title, intensity, and whether you've answered it yet. Tap any row
  to jump straight to that card instead of clicking Next repeatedly.
- The choice between list view and one-at-a-time persists as you move
  between headings; the search box clears each time you open a different
  heading.

## 1.4.2 — CSV category matching no longer case-sensitive

- Fixed CSV import creating a duplicate, wrongly-cased heading whenever the
  CSV's category text didn't exactly match an existing heading's
  capitalization (e.g. "teasing & dirty talk" would create a second
  heading instead of filing into the real "Teasing & Dirty Talk"). Category
  matching is now case-insensitive, and cards always file under the
  heading's real, correctly-cased name — the CSV's own casing no longer
  matters.

## 1.4.1 — CSV can specify which image file goes with each card

- CSV import now accepts an optional `image_filename` column. If present,
  "Attach images to cards" matches on that exact filename first, before
  falling back to matching by card title — useful if your image files use
  their own naming (like `img014.jpg`) rather than matching each card's
  full title.

## 1.4.0 — bulk image import

- Added "Attach images to cards" on the Boundaries tab — select many image
  files at once and each gets matched to its card automatically by
  filename (e.g. "Missionary Position.jpg" matches the card titled
  "Missionary Position"; underscores, dashes, and capitalization don't
  matter). Files that don't match any card title are listed clearly rather
  than silently dropped.
- Added a simple "Attach an image" / "Replace image" option to individual
  cards too, for anything that doesn't match automatically or needs fixing
  one at a time.

## 1.3.1 — CSV import handles accents, flags shifted columns

- Fixed accented values (e.g. "Risqué") being rejected — values are now
  normalized to strip accents before checking, not just lowercased.
- When a row's max_intensity value is long, clearly-not-a-keyword text
  (usually a sign that an un-quoted comma in an earlier column shifted
  everything over), the error message now says so directly and points you
  at the likely cause, instead of just "invalid max_intensity".

## Database update — final heading names

- Renamed the 6 headings for clarity: Teasing & Dirty Talk, Touch &
  Sensation, Positions & Core Acts, Dominance & Surrender, Roleplay &
  Fantasy, Risk, Public & Exhibition. Same 6 categories as before, same 54
  cards, just clearer names. Database-only, no app update needed.

## Database update — reorganized headings

- Consolidated the original 13 headings into 6 clearer ones: Communication
  & Teasing, Physical & Sensory Play, Sexual Positions & Acts, Power &
  Control, Roleplay & Fantasy, Public/Risk & Novelty. Every existing card
  was remapped to its new heading — nothing was lost. Database-only change,
  no app update needed for this one.

## 1.3.0 — delete boundary cards

- You can now delete boundary cards, which wasn't possible before (no
  database policy allowed it). Three levels: delete a single card from
  inside its deck, delete every card in one heading at once, or delete
  every card across every heading (headings themselves stay — only the
  cards inside them are removed). Each asks for confirmation first.
- Deleting a card also removes any private answers either of you gave to
  it — nothing orphaned left behind.

## 1.2.1 — CSV import no longer case-sensitive

- Fixed the CSV import skipping every row when the source file's column
  headers weren't exactly lowercase (e.g. "Category" instead of
  "category") — headers are now normalised automatically regardless of
  case or spacing, and a few common alternate names (heading/category,
  name/title, description/explanation, intensity/max_intensity,
  type/suitable_for) are accepted too.

## 1.2.0 — bulk import from CSV

- Added a CSV import to the Boundaries tab ("Import from CSV") for adding
  many cards at once instead of one at a time. Expects columns: category,
  title, explanation, max_intensity, suitable_for. Headings that don't
  exist yet are created automatically as part of the import. Images aren't
  part of the CSV — add those individually afterwards if wanted.
- Invalid rows (missing title/category, or an unrecognised intensity) are
  skipped rather than breaking the whole import, and you get a summary of
  what was added versus skipped, with the reason for each skip.

## 1.1.1 — original answer scale

- Replaced the 4-option answer scale (which was close to Privé's own
  wording) with an original 5-tier one: Full Spark, Warming Up, Blushing
  Yes, Just For You, Cold Card. Same underlying idea — enthusiastic
  through to hard no — just our own words, with a bit more room in the
  middle, and tied into the app's existing Heat Meter language.
- The mutual-boundary matching logic was rewritten for the 5-tier scale —
  a "Cold Card" from either side still excludes it outright; otherwise the
  less enthusiastic of the two answers sets how cautiously you start.

## 1.1.0 — headings, your own cards, and a lighter look

- Colour scheme reworked: no more dark "chocolate" theme. Each of you picks
  a lighter theme at signup (or once, on next login, if your account
  already existed) — purely a colour choice, nothing else depends on it.
- The boundary questionnaire is now built around **headings** you manage
  yourselves — Positions, Roleplay & Fantasy, Control & Surrender, Toys &
  Accessories, and the rest of the original set — rather than a fixed demo
  question list. Add your own headings, and your own cards under each one
  (title, description, an optional photo, suggested intensity), from inside
  the app.
- Cards are browsed one at a time as a deck under each heading, with an
  image if you've added one, rather than one long scrolling list.
- Images you attach are stored privately — only your couple can ever see
  them, enforced at the storage level, not just hidden in the interface.
- The answer scale changed to four options — Love this / Yes, but I'm shy /
  If they want it / Definitely no — and the mutual-boundary logic was
  rewritten to match: a "definitely no" from either side still excludes it
  completely; otherwise the less enthusiastic answer sets how cautiously
  you start.
- Fixed a real security gap found while building this: several database
  functions were callable by anyone, even without being signed in, because
  Supabase grants that access by default on new functions and revoking it
  from the general "public" group alone doesn't remove it — the direct
  grant to anonymous visitors needs revoking explicitly too. All functions
  are now confirmed, by direct database query rather than just the
  automated check, to be callable only by signed-in players.

## 1.0.3 — invite code no longer disappears

- Fixed `gen_random_bytes` errors when generating an invite code — a
  security-hardening change had accidentally cut off the database function
  from a schema it depended on.
- The app now shows a proper "waiting on your partner" screen with your
  invite code any time you're paired to a couple but your partner hasn't
  joined yet, instead of only showing the code once, immediately after
  generating it. Refreshing the page (or coming back later) no longer loses
  it. You can also generate a fresh code from that screen if the original
  one expires.

## 1.0.2 — back to a single file

- Merged `app.js` back into `index.html`, matching the same single-file
  pattern as Lily's app. There's now exactly one file the website needs.
  This removes the class of bug that caused 1.0.1 — nothing to keep in
  sync between two files, nothing that can be uploaded out of order.

## 1.0.1 — startup crash fix

- Fixed a bug where the app hung permanently on "Opening…" for every user.
  Cause: the app's own Supabase connection variable was named `supabase`,
  which collided with the name the Supabase library itself uses internally,
  causing the whole script to fail silently before it could run.
- The version number now shows even while the app is still loading, and is
  tappable from the top bar to see the full changelog and confirm you're on
  the version you expect — no more guessing whether an update actually took
  effect.

## 1.0.0 — first usable version

- Private account creation and one-time-code couple pairing.
- Independent, private boundary questionnaire (small demonstration set across
  10 categories) with strict per-user privacy — no partner can read the
  other's raw answers, by database policy, not just app design.
- Server-side mutual boundary calculation exposing only the joint result.
- Dare creation restricted to categories/intensities inside the current
  shared boundary, enforced server-side.
- Full dare workflow: send, teaser-then-reveal, accept, decline, counter,
  complete (four completion types, no proof stored in-app).
- Automatic, server-timestamped scoring with a time-based multiplier;
  Reunion-type dares scored against their agreed deadline rather than a
  short response window.
- Individual scoreboard and shared Heat Meter (0–100%, rises on completion).
- Configurable rewards with locked/unlocked state and optional
  Heat-Meter-threshold auto-reveal.
- In-app notifications (discreet wording — no dare content shown outside the app).
- Dare history tab.
- Realtime sync between two devices via Supabase realtime subscriptions.
- Mobile-first design, installable via Add to Home Screen.
- Row Level Security on every table; direct dare inserts blocked at the
  database level (must go through the boundary-checked function).

## Known gaps / next steps (not yet built, on purpose)

- Push notifications (currently in-app only).
- Editable question/dare library UI (currently edited via SQL).
- Gradual Heat Meter decay after inactivity.
- Imported dare packs.
- Anything from the "out of scope for v1" list in the original brief.
