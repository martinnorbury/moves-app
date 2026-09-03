# Changelog

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
