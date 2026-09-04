# Changelog

## 1.29.0 — quality bonus, turn nudge, post-completion question

- Added a bonus-only quality reaction: after a move is completed, whoever
  sent it (not the person who did it) can react Meh/Good/Loved it. Good
  adds a 10% bonus, Loved it 25% — on top of the guaranteed intensity+speed
  points, never reducing them. Tested directly: 10 base points at the
  fastest multiplier (20 total) plus a Loved it reaction correctly landed
  at 25 total, and a second reaction attempt was rejected as expected.
- Added a soft turn nudge on Home — after either of you completes a move,
  it says whose turn it "is" to send the next one, but never blocks
  either of you from sending anytime regardless.
- Added the post-completion follow-up: mark a move complete, and if
  there's an unanswered card left in that same heading, you're prompted
  with it right there — answer it or skip, feeding straight back into
  that heading's running average.
- Caught and fixed a genuine syntax error (a missing closing brace) before
  shipping this time, per the earlier reminder to actually check.

## 1.28.1 — actually fixed the column mismatch this time

- Removed "Attach images to cards" entirely from the top-level Questions
  screen, rather than repositioning it — repositioning kept the
  structural mismatch (one extra line on Questions) and risked text
  wrapping making it worse on narrower screens. Both columns now end with
  exactly one short link each, genuinely matching.
- Per-card "Attach/Replace image" is untouched and still works from
  inside any individual card. The bulk-match-by-filename shortcut isn't
  reachable from a button right now — say if you want it back somewhere
  and I'll find it a home that doesn't fight the layout.

## 1.28.0 — matching layout, intensity search, and editing cards properly

- Questions and Dares now have exactly matching button rows — "Attach
  images to cards" moved from a prominent top-level button down to a
  secondary link (same tier as "Delete all"), so both columns line up.
  The feature itself is untouched, just relocated.
- Search on both sides now matches intensity too (Tease/Risqué/Bold/Wild),
  not just title — search results show the matching intensity pill so
  it's clear why something showed up.
- Added actual card editing — never existed before, despite looking like
  it should have. "Edit card" now sits next to Attach image/Delete on
  every card, letting you change its heading, title, description,
  intensity, type, and general-question flag, all in one form.

## 1.27.0 — search box above both Questions and Dares

- Added a search box at the top of each Admin column, searching by title
  across every card or dare regardless of which heading it's under —
  results show inline with their heading, tap to jump straight in
  (directly to the card for Questions, straight to the edit form for
  Dares) rather than needing to know which heading to look under first.
- Fixed a focus bug caught before it shipped: since both search boxes sit
  on screen at once, typing in one was at risk of yanking focus to the
  other after every keystroke. Only the box actually being typed in keeps
  focus now.

## 1.26.1 — Questions and Dares now behave identically

- Fixed two inconsistencies: Add/Import buttons were at the bottom on
  Questions but the top on Dares — both now sit at the top. Questions
  required tapping a heading to see its cards; Dares dumped every dare
  into one long flat list instead. Dares now works exactly the same way
  as Questions — heading list first, tap to drill into that heading's
  dares, with the same delete-all-in-this-heading option once you're in.

## 1.26.0 — Admin split into Questions and Dares side by side

- Admin now shows two columns: Questions (headings and their cards) on
  the left, Dares (the library) on the right — both grouped by the same
  headings, same list/row format either side.
- On a wider screen, the app's usual 520px width limit widens to 900px
  just for the Admin tab, so the two columns have real room instead of
  being squeezed. On a narrow phone screen, it drops back to a single
  stacked column automatically — Questions first, then Dares — so it
  still works fine there too.

## 1.25.1 — Browse headings & answer cards removed from Kinks

- Removed the "Browse headings & answer cards" link from Kinks entirely,
  as asked. It's no longer reachable from anywhere except the Admin tab.
- Since that was the only path into the non-admin version of Setup, the
  whole dual-mode system behind it — the adminMode parameter threaded
  through Setup, the deck view, and the card view, plus the now-unused
  viewingSetup state and its back button — was dead code once that link
  was gone. Removed all of it rather than leave it unused.

## 1.25.0 — full admin control over the dare library

- The dare library now has the same admin capabilities headings and
  cards already had: browse every dare (grouped by heading), add one at
  a time through a form, tap any dare to edit it, and delete individually
  — not just bulk CSV import and delete-all-at-once.
- Database access for editing/deleting individual dares already existed
  from when the library was first built; this was purely a missing app
  screen, now added.

## 1.24.0 — dare library, and dares now validate against heading access

- Dares are now judged against the heading-level running average — the
  same "Perfect Match / Good Match / Getting Warmer / Worth A Try" system
  driving everything else — instead of the old per-card system. Tested
  directly against the database: a Perfect Match heading allows Wild, a
  Getting Warmer heading rejects anything above Risqué, and a closed
  heading rejects everything, even Tease.
- Added a dare library: admin imports a CSV of pre-written dares (each
  tagged with a heading and a fixed intensity), and "Create a move" now
  suggests matching ones for whichever heading you pick — capped to what
  that heading currently allows, so you're never shown something outside
  the boundary. Writing your own from scratch is still one tap away.
- Type (Apart/Together/Either/Reunion) is deliberately not part of a
  library dare — you pick that fresh every time you send one, since it
  depends on the moment, not the dare itself.
- Library import is admin-only, same as everything else that adds or
  changes content; browsing suggestions and sending a move is usage,
  open to both accounts.

## 1.23.0 — Step 1 complete milestone

- Added a genuine one-time celebration screen, shown once ever (a real
  database flag, not something that reappears every login) once every
  heading has moved past "waiting on both of you" — meaning you've both
  actually answered all 6 general questions. Shows a recap of where
  everything landed, then hands off to "Step 2: your first move."

## 1.22.1 — Admin holds only content-management tools, nothing else

- Removed "Your card report" from the Admin tab entirely — it was
  reporting data, not a content-management function, and it duplicated
  the per-heading expansion already on Kinks showing the same thing.
  Admin now contains exactly five things: add a heading, add a card,
  import CSV, attach images, delete — nothing that only reads or reports.
- The test going forward: if an action doesn't create, modify, or remove
  content, it isn't admin — regardless of which screen it happens to live
  on. Browsing headings and answering cards under Kinks stays there
  because it fits that test; it was never misplaced.

## 1.22.0 — a personal welcome, with your own photo

- Home now opens with "Welcome back, [your name]" in large type, plus a
  tappable avatar circle — tap it to add or change a photo. Shows your
  initial in gold until you've set one.
- Your photo is stored privately (its own storage bucket, only your own
  account can ever read or write it) and isn't shown anywhere else in the
  app or to your partner — purely a personal touch on your own Home
  screen.

## 1.21.0 — Admin is now a genuinely separate tab

- Third time's the fix: admin tools weren't actually separated before,
  just conditionally shown on a link inside the shared Kinks screen. Added
  a real "Admin" tab in the bottom bar — visible only on your account,
  invisible entirely on Jacki's, with its own direct entry point.
- "Manage headings, cards & content" is gone from the Kinks screen
  completely. What's left there ("Browse headings & answer cards") is
  now always the plain browsing/answering experience, for both accounts,
  with zero admin tools mixed in — even on your own account, if you
  happen to reach a heading that way instead of through Admin.
- Using vs. maintaining the app are now two separate paths through the
  whole app, not just two states of one screen.

## 1.20.0 — general question hands off once you've answered enough, plus a full answer review

- Heading averages now genuinely hand off from the general question to
  specific cards: once 3 or more specific cards in a heading have been
  answered by both of you, the general question stops counting toward
  that heading's average entirely — only the specific cards drive it from
  there. Below 3, the general question still counts, since there's
  nothing else to go on yet.
- Added "Review & edit all your answers" — every question you've
  personally answered, across every heading, in one searchable list with
  your current answer right there and changeable on the spot. No more
  hunting through Setup → heading → card to check or change something.
  Available to both accounts, since it's your own answers, not a content
  management tool.

## 1.19.1 — each question shows its own colour-coded match, same wording as headings

- Replaced grouped tier headers with a per-question pill — the same
  colour-coded badge used on headings (Perfect Match / Good Match /
  Getting Warmer / Worth A Try), now shown right on each individual
  question's own row, sorted best-match first. One consistent system
  instead of two.
- Dropped the "up to Tease"-style intensity text on these rows — same
  confusing wording flagged and removed elsewhere, just resurfacing here.
  Applied to both the shared per-heading expansion and the admin card
  report, so they read the same way.

## 1.19.0 — renamed to Kinks, moved first, expandable per-heading detail

- Renamed the "Compass" tab to "Kinks" and moved it to the front of the
  tab bar.
- Each heading in the list is now expandable — tap it to see every
  question you've both answered there (general and specific), grouped by
  match tier, same as the admin card report but scoped to just that one
  heading and visible to both of you. Cards excluded by a Cold Card are
  still only counted, never named, same privacy rule as everywhere else.
- Worth knowing: this does show individual specific-card results on the
  shared tab, which is the same underlying data as the admin-only card
  report, just organized by heading instead of tier. If that turns out to
  be more than intended, it's a quick change to restrict.

## 1.18.0 — heading access is now a running average, tab renamed to Compass

- Heading access no longer looks only at the general question — it's now
  a running average across every question you've both answered in that
  heading (general plus specific cards). Each individual card keeps its
  own untouched score; this only changes the heading-level summary. As
  planned: the more that's been answered, the less any single new answer
  shifts the average — except a genuine Cold Card, which always closes
  the whole heading regardless of everything else answered there.
- Each heading now shows how many questions its average is based on, so
  it's visible why a heading is positioned where it is, and why it'll
  move less as more gets answered.
- Renamed the "Boundaries" tab to "Compass" — same screen, same content,
  just a name that fits an ongoing reference screen better than a
  one-time setup step.

## 1.17.1 — Your card report actually moved to admin-only now

- Corrected a misread of an earlier request: "Your card report" was still
  showing on the shared Boundaries screen for both accounts. It's now
  removed from there entirely and lives only inside the admin-only part
  of Setup — Jacki's account never sees it, regardless of which screen
  she's on.

## 1.17.0 — 5 outcomes for 5 answer levels, unified wording

- Fixed heading access silently collapsing two different combined scores
  (2 and 1) into one "Getting Warmer" bucket — there are now 5 distinct
  outcomes, one per possible combined answer, matching the 5-level
  gauge properly: Perfect Match, Good Match, Getting Warmer, Worth A Try,
  and Not on the Table.
- Heading access and the card report now use the exact same tier names,
  so the two features read as one consistent system rather than two
  slightly different vocabularies for the same idea.

## 1.16.0 — content management is now Martin-only

- Added an admin flag, currently set on Martin's account only. Adding
  headings, adding cards, importing CSVs, attaching images, and deleting
  anything now requires it — enforced in the database itself (tested
  directly: Jacki's account is rejected with a clear error if it tries
  any of these, even bypassing the interface entirely), not just hidden
  in the app.
- Jacki's account no longer sees any of those buttons at all — but still
  has full access to browse every heading and answer cards, since that's
  essential to the matching actually working. Wording adjusts accordingly
  ("Browse headings & answer cards" instead of "Manage headings, cards &
  content").

## 1.15.0 — one less screen in the way

- Removed the one-time "Where you both stand / Continue to the app"
  screen that used to appear right after the wizard finished — it showed
  the same information the Boundaries tab now shows persistently, so it
  was just an extra tap for nothing. Finishing the 6 general questions (or
  the partner-started teaser, if that showed first) now drops you
  straight into the normal app.

## 1.14.0 — icons, wording, a real bug fix, and one redundant section removed

- Fixed a real bug: the report screen said "you don't need to wait for
  Jacki" regardless of who was actually logged in — it should say whoever
  your actual partner is. Confirmed while investigating: Martin and Jacki
  are genuinely separate accounts, this was purely a hardcoded name.
- Filled in the 3 middle gauge stops with colour-graded hearts (orange,
  white, blue) between the red heart and the snowflake, so the gauge
  reads as one continuous gradient instead of 3 blank circles.
- Removed "Discover/Explore/Unleash" wording from the heading-access
  labels — now just Getting Warmer / Good Match / Perfect Match / Not on
  the Table. The underlying tiers still exist for later use, just not
  named in the interface yet.
- Added an overall rollup line above the per-heading breakdown — a quick
  "X Perfect Match · Y Good Match · Z Getting Warmer" summary across all 6
  headings at a glance.
- Removed the old "Your shared boundary" section — leftover from before
  the general-question wizard and card report existed, showing the same
  information as the card report below it but with more confusing,
  legacy wording ("up to Tease"). One less thing saying the same thing
  two different ways.

## 1.13.0 — "your partner already started" teaser

- If you log in and your partner has already answered some of the 6
  general questions but you haven't, you now see a screen letting you
  know, with a shuffled grid of colour blocks showing the flavour of
  their answers — no link back to which colour belongs to which
  question, so nothing is revealed before you've answered too. A legend
  explains the colours, and it's explicit that your own answers stay just
  as private going the other way.
- Shown once per login, right before the wizard starts.

## 1.12.0 — joint card report, grouped by how matched you are

- Added "Your card report" to the Boundaries tab — every specific card
  you've both answered, grouped into Favorites (full agreement, both Full
  Spark) down through Strong Interest, Worth Trying, and If You're Both Up
  For It, same weakest-answer-wins logic used everywhere else in the app.
- Cards excluded by a Cold Card are counted but not listed by title —
  showing exactly which ones sits too close to revealing whether it was a
  mutual or one-sided no, which the app has never done anywhere else
  either.
- Empty for now since no specific cards have mutual answers yet — this
  fills in as you both go answer cards under Setup.

## 1.11.0 — Boundaries is now pure reporting; content moved to Setup

- The Boundaries tab is now just a report: your 6 general answers (shown
  as editable gauges, right there — change any of them any time, no need
  to wait for Jacki), your shared boundary, and heading access. Nothing
  about managing content lives here anymore.
- Everything else — browsing a heading's specific cards, adding new cards
  or headings, CSV import, attaching images, deleting cards — moved to a
  new "Setup" area, reached via "Manage headings, cards & content" at the
  bottom of the report. Same functionality as before, just out of the way
  of the day-to-day reporting view.
- Your own general answers are always visible and editable regardless of
  whether your partner has answered yet — the report never hides or locks
  your side waiting on theirs.

## 1.10.0 — a proper landing after the wizard, instead of a sparse Home tab

- Fixed the status counter comparing against every card (~60) instead of
  just the 6 general ones — after finishing the wizard, it was showing
  something like "58 boundary questions still to answer," which combined
  with an empty Home tab (no dares yet) could easily read as broken.
- Added a report screen shown once, right after the wizard finishes: your
  own answers to the 6 general questions, then where each heading
  currently stands (using the existing heading-access readout). If your
  partner hasn't finished their own 6 yet, it says so plainly and shows
  your side only — nothing pretends to be final before it is. A
  "Continue to the app" button moves on from there.

## 1.9.2 — gauge flipped: cold left, heart right

- Reversed the gauge so the snowflake sits on the left and the heart on
  the right, with the colour track flipped to match. Purely visual —
  which answer maps to which underlying value hasn't changed.

## 1.9.1 — gauge without the text labels

- Removed the "Full Spark / Warming Up / etc." text underneath the gauge
  on general questions — that wording fits judging a specific act, not a
  broad temperature check, so the gauge now stands alone: just the heart,
  the three plain stops, and the snowflake. The underlying answer values
  are unchanged, only the on-screen labels are gone.

## 1.9.0 — heading access algorithm (readout only, not enforced yet)

- Added the logic you described: each heading's combined general-question
  answer now determines which tiers (Discover/Explore/Unleash) are
  eligible — a Cold Card from either side closes the heading entirely;
  otherwise the less enthusiastic answer decides how far it opens (both
  Full Spark = everything; one step down = Discover & Explore; anything
  more moderate = Discover only).
- New "Heading access" section on the Boundaries tab shows exactly where
  this places each heading right now, so you can verify the algorithm
  before anything is built on top of it.
- Deliberately not enforced anywhere yet — specific cards are still
  browsable and dares still creatable regardless of this result. That's
  the intentional next step once the logic itself is confirmed correct.

## 1.8.0 — heart-to-freezing gauge for general questions

- The 6 general "where do you sit on this heading" questions now show a
  visual gauge instead of a stacked list of buttons — a heart at the warm
  end, a snowflake at the cold end, three plain stops in between. Same
  five underlying answers as everywhere else (Full Spark through Cold
  Card), just a better fit visually for a broad temperature check than
  for judging one specific act.
- Specific cards (Missionary Position and the rest) are unchanged — still
  the button list, which reads better for a discrete yes/no-ish choice.

## 1.7.0 — wizard only covers the 6 general questions

- Fixed the after-login wizard, which was walking through all ~60 specific
  cards instead of just the 6 general "where do you sit on this heading"
  ones. Cards are now explicitly marked general-or-specific (a new
  is_general flag) — the wizard only ever shows the general ones; specific
  cards stay something you browse into a heading for, by choice.
- Added an "is this the general question for this heading" checkbox to the
  manual add-card form, and an equivalent is_general column to CSV import,
  so this stays correct as you add more headings later.
- Cards marked general show a small "General" badge when browsing a
  heading, so it's clear which one that is.

## 1.6.0 — guided wizard for unanswered cards

- After logging in, if you have any unanswered cards, the app now presents
  them one at a time in a fixed order (heading by heading, in the order
  they were added) instead of leaving you to find the Boundaries tab
  yourself. Answer one and the next appears automatically — same pattern
  as the existing "you need to pair first" screens, just for this.
- Includes a "Skip for now, come back to this later" link so nobody's ever
  genuinely stuck on a card they're not ready to answer — skipped cards
  just don't block you for the rest of that session, and reappear next
  time you open the app (still unanswered, same as any other unanswered
  card).
- Once every current card has an answer (or been skipped), you land in the
  normal app as before. Adding more cards later — one at a time, via CSV,
  however — naturally brings the wizard back for just the new ones.

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
