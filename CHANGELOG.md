# Changelog

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
