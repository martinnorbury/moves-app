# Changelog

## 1.67.0 — Forfeits gets search and grouping, matching Questions and Dares

- Was a completely flat, ungrouped list — same gap Questions and Dares
  used to have. Added a search box (same pattern: type to filter, tap a
  result to jump straight to editing it). When not searching, forfeits
  now group into collapsed sections — Non-intimate as one group, then
  each intimate Temptation as its own — tap to expand instead of
  scrolling through everything at once.

## 1.66.1 — a real regression from the polling fix, now guarded properly

- The 45-second poll and visibility/focus refresh added a couple of
  versions back could fire while a modal was genuinely open and being
  interacted with — a background render re-inserts the same modal HTML
  but never re-attaches its button handlers, since only the function
  that originally opened it does that. The modal looks completely
  normal but stops responding to anything except clicking outside it —
  exactly what happened with the follow-up question. The doer-feedback
  chain added last version made this more likely just by keeping a
  modal open longer.
- The pre-existing 30-second countdown timer already guarded against
  this correctly (`!state.modal`) — this was a known, established
  pattern I just didn't apply consistently to the newer polling or to
  the realtime subscription handlers, which had the identical
  vulnerability already. Fixed all of them the same way: skip the
  render while a modal's open, but keep loading fresh data in the
  background regardless, so it's all there the moment the modal closes.

## 1.66.0 — a real content-feedback loop, feeding into Grok

- New, separate mechanic from the existing sender-rates-performance
  reaction (that one's untouched, still awards bonus points): right
  after completing a dare, whoever did it now gets asked "How did that
  feel?" — meh, good, or loved it — purely informational, no points,
  specifically about the dare's content rather than the completion
  itself. Shown proactively as part of the celebration, not buried in
  History.
- Sent dares now trace back to which library entry they came from
  (blind draws only — write-your-own has no library origin to link to),
  which is what makes the export actually useful rather than a flat
  list of one-off completions.
- New "Export feedback (for Grok)" button in Admin, next to the existing
  dare-library export: one row per library dare, with how many times
  it's been sent and the meh/good/loved-it breakdown from everyone who's
  done it — exactly the shape needed to hand to Grok for the next batch.
- Tested every permission path directly, using transactions rolled back
  afterward so nothing was left behind: the creator is correctly
  rejected from giving doer feedback on their own dare, the recipient
  can, and the export is correctly admin-only.

## 1.65.0 — reward alerts, and explaining the general-question lock properly

- Checked the lock mechanic directly rather than assuming: it's working
  correctly (4 mutual specifics in Positions & Core Acts, general
  question genuinely excluded from the score). The real issue was that
  the slider stays interactive — correctly, you should always be able to
  see and change your own answer — but nothing told you it had stopped
  affecting the score, so moving it and seeing nothing happen looked
  like a bug rather than confirmation the lock was working. Added a
  clear note directly on the slider once a temptation passes the
  threshold.
- Rewards had no proactive signal at all — crossing a threshold gave no
  dot, no message, nothing. Fixed both ways: the same tab-bar dot
  pattern already used for dares and comparisons now covers Rewards too
  (any revealed, unclaimed reward), and a toast fires the moment a
  reward newly crosses its threshold, seeded on first load so it never
  fires retroactively for something already unlocked before this
  session started.

## 1.64.0 — the actual root cause: RLS silently blocks Realtime, not connection reliability

- This was never a connection-reliability problem. Confirmed directly:
  `boundary_answers` RLS correctly restricts each person to SELECT only
  their own rows — necessary for privacy — but Supabase Realtime checks
  RLS before delivering any change to a subscriber. Since Jacki is never
  allowed to SELECT Martin's answer row, her subscription to that table
  could never receive that event, regardless of the filter, the
  connection, or anything else. Every previous fix in this area was
  correctly built but aimed at the wrong layer.
- Fixed properly this time, the same way dares already solves the same
  category of problem: a database trigger now inserts a notification
  (which the recipient genuinely can see under RLS) whenever someone
  answers a new question, and the existing, already-reliable
  notifications subscription picks it up and runs the same comparison
  check. Tested the trigger directly inside a transaction that was then
  rolled back, so nothing committed or broadcast live — confirmed the
  notification is created correctly, addressed to the right person, then
  confirmed the rollback left no trace at all.
- Removed the direct `boundary_answers` subscription entirely, since
  it's now confirmed structurally incapable of ever firing — dead code,
  fully superseded by the trigger. The periodic poll and foreground
  refresh from the last two versions stay as a general safety net, but
  the live path should now work properly on its own for this.

## 1.63.1 — a genuinely universal fallback, not a mobile-specific one

- The previous fix only refreshed on visibilitychange/focus — a real
  gap for two windows on separate screens that just stay open and
  visible the whole session, since neither event ever fires in that
  case. Added a straightforward 45-second periodic check, independent
  of visibility entirely, as the actual universal guarantee — covers
  mobile backgrounding, tabs that never lose focus, anything.

## 1.63.0 — the real fix: refresh on foreground, not just on live events

- Every realtime fix so far assumed the WebSocket connection stays alive
  continuously. On a phone, it doesn't — locking the screen, switching
  apps, a brief signal drop can silently kill it, and anything that
  happened while disconnected is never retroactively delivered even
  once it reconnects. That's not a bug to patch, it's a fundamental
  limit of push-based realtime on mobile — no amount of hardening the
  live-event path was going to fully solve it.
- Added what actually solves it: the app now does a full quiet data
  refresh whenever it becomes active again — switching back to it,
  unlocking the phone, anything that makes the tab visible — completely
  independent of whether the realtime connection survived. This doesn't
  show the "Opening…" screen (that would be its own annoyance, flashing
  every time someone glances at their phone) — a new silentRefresh()
  path reuses the same data-loading logic without the loading-screen
  blank-out, then runs the same engagement checks that would show the
  comparison-question modal if something's pending.
- This is the actual reliability guarantee going forward: realtime is
  now a nice-to-have for near-instant updates while the app is open, and
  foreground-refresh is what guarantees correctness regardless of what
  the connection did in between.

## 1.62.0 — Type removed entirely from dare creation

- Clarified first: Type was never removed in the earlier fix — that fix
  added validation to it (which apparently read as removal). This time
  it's genuinely gone: both Type dropdowns removed from the create-dare
  screen, the parameter dropped from create_dare() itself (tested
  end-to-end — grants verified, no duplicate function versions), and the
  now-pointless Type pill removed from every dare card.
- Reunion's special scoring formula went with it, since there's no way
  left to mark a dare as Reunion — every dare now uses the standard
  speed-tier multiplier. The database column stays (existing dares keep
  their history) with a default of 'either' for anything new.
- Left one thing alone on purpose: boundary question cards (the Kinks
  content itself) have their own separate "suitable for" field that
  happens to reuse the same four labels — that's authoring metadata for
  cards, a different concept from what's sent as a dare, and wasn't
  part of what was asked.

## 1.61.0 — Kinks gets a persistent indicator, not just a live pop-up

- Checked directly: Jacki genuinely does have a pending comparison
  question sitting there ("Candle Position") — the underlying logic is
  correct, but the only way she'd find out was catching a live realtime
  event at the exact right moment, or refreshing. That's inherently
  fragile — a dropped connection, a backgrounded tab, anything, and it's
  silently missed with nothing left behind to show for it.
- Added the reload-independent fallback: the same dot the Dares tab
  already uses for new dares now also appears on Kinks when something's
  pending, refreshed on every load regardless of whether any realtime
  event fired. And since a dot alone doesn't actually get you to the
  question, added a tappable callout right at the top of Kinks —
  "New from Martin — N questions waiting for your take" — that opens
  the same modal directly. Both stay in sync automatically once
  answered, since the existing code already refreshes this list after
  every answer and skip.

## 1.60.0 — the next-reward bug, and rewards become genuinely mutual

- Found the actual cause of the 50%-instead-of-25% bug: rewards were
  loaded ordered by creation date, not by threshold — the "next reward"
  logic just took the first array match, which only happened to be
  correct if rewards were created in threshold order. Fixed to order by
  threshold directly, which is what the logic actually depends on. Also
  worth clarifying: "Something to look forward to" isn't a reward's
  name — it's the teaser text for "A proper date night" (the real 25%
  reward), shown because it hasn't unlocked yet.
- Rewards were admin-only to add, edit, or delete, same as the dare and
  forfeit libraries — but the reasoning for that pattern doesn't apply
  here. Dares and forfeits benefit from single-curator quality control;
  a reward is something both of you already know about, work toward
  together, and experience together, so keeping it gated to one account
  didn't fit. Moved the whole thing: either partner can now add, edit,
  or delete rewards directly from the Rewards tab, tested against
  Jacki's account specifically to confirm it actually works end to end.
  Removed the now-duplicate admin section (with a note pointing to where
  it moved) and the CSV import/export for rewards, which made much more
  sense for the 100+-item dare and forfeit libraries than for a handful
  of shared rewards.

## 1.59.0 — Type now actually validates against the Temptation

- Direct answer to the question that started this: Type was purely
  cosmetic (a label on the card) except for Reunion, which uses a
  different scoring formula — apart/together/either had zero functional
  difference between them, and nothing stopped a nonsensical combination
  like Apart + Positions & Core Acts.
- Fixed properly, both sides: the Type dropdown now only offers options
  that are physically possible for the selected Temptation (Apart is
  excluded for Touch & Sensation and Positions & Core Acts, on both the
  write-your-own and blind-send forms), and the same rule is enforced in
  the database function itself, not just the UI. Tested directly:
  Apart + Positions & Core Acts is correctly rejected server-side,
  Together + the same category goes through fine.

## 1.58.0 — the actual cause of the missing comparison prompt, and answers finally collapse by Temptation

- Checked the database directly rather than guessing again, and found
  it: Jacki's `seen_wizard_intro` flag was stuck false — almost
  certainly left over from directly testing "Preview my onboarding
  again" against her account a few versions back, without her fully
  re-walking the flow afterward — even though she'd genuinely finished
  everything (all six answered, explainer seen, Step 1 seen). My
  onboarding-complete check required that flag specifically, so it
  silently blocked every live comparison-question check for her ever
  since. Repaired her data directly, and — more importantly — rewrote
  the check itself to stop depending on that flag at all. It's now based
  on the actual condition that controls whether an onboarding screen can
  show (no pending general questions), which can't drift out of sync the
  way a sticky flag can.
- "Review & edit all your answers" was a flat, ever-growing list with
  no way to collapse anything — asked for a few times now and never
  properly fixed. Rebuilt it to match the accordion already used on
  Kinks: collapsed by Temptation by default, tap to expand and edit
  what's inside. Searching still works as before, falling back to a
  flat filtered list since collapsing doesn't help once you're
  specifically looking for something.

## 1.57.0 — blind means blind through the whole thing, not just until accepted

- Real gap in what "blind send" actually did: it only hid content while
  status was still 'sent' — the moment the recipient accepted, the
  sender could immediately go check "Sent by you" and read everything,
  well before the dare was actually done. Extended concealment through
  accepted, in_progress, and countered — a blind dare now only reveals
  itself to the sender once it's genuinely completed (or declined,
  since there's nothing left to protect at that point).
- Found and fixed three separate places the title itself was leaking
  even with that fixed — the dare card's title was never gated by reveal
  status at all, the Playroom "Dare In Play" banner (the single most
  prominent thing in the app, shown the moment you open it) had the same
  gap, and the "accepted" notification toast printed the title directly.
  Titles can be spoilers on their own — swept every place a dare's
  title or instructions get displayed to make sure nothing else leaks
  the same way.

## 1.56.0 — comparison questions now arrive live, and Kinks stays readable at scale

- Found and fixed the actual cause of "only shows up on refresh": the
  `boundary_answers` table was never added to the realtime publication,
  and nothing subscribed to it either — same class of bug as the
  dares/notifications/rewards realtime issue from earlier, just in a
  table that got missed. When your partner answers a follow-up or
  comparison question, you should now get prompted live, without needing
  to reload.
- Kinks was already collapsed at the top level (six Temptations,
  nothing expanded by default), but once you expanded one, every single
  answered card showed with no limit at all — that's the part that would
  genuinely become unreadable after enough dares. Capped it to 6 by
  default with a "Show all N" toggle, so it stays scannable regardless
  of how much history builds up underneath.

## 1.55.0 — genuinely blind, no alternative, plus sender picks intensity

- Removed browsing and "pick one at random but let me see it" entirely —
  those defeated the whole point. Drawing a library dare is now blind,
  full stop; the only other option is writing your own from scratch,
  which is a different thing entirely since you obviously know what you
  wrote.
- Added intensity as a choice on the blind draw — the sender picks the
  Temptation, type, and intensity (still capped by what that Temptation
  currently allows), and the specific dare within that combination is
  what stays hidden. This is safe to let the sender choose because the
  recipient always has the counter as a safety valve if it's not quite
  right once they see it.
- Cleaned up all the now-dead code from the removed browse/peek paths —
  nothing left pointing at elements or functions that no longer exist.

## 1.54.1 — the full dare list no longer dumps itself on screen automatically

- "Or browse and choose one yourself" now actually does what it says —
  it's a real link you tap to reveal the list, rather than the entire
  list already sitting there regardless. This predates the blind-send
  work, but became a real problem once there were three options stacked
  above it — the modal was showing everything at once with no reason to.
  Changing Temptation still refreshes the list live, but only once
  you've actually opened it.

## 1.54.0 — genuine blind sending, so the sender loses their unfair edge too

- Real structural gap, not a content problem: the sender always got to
  read a dare's exact content before deciding to send it, meaning they
  could cherry-pick whichever one suited them, and always knew exactly
  what was coming — even for random-drawn picks, since "Surprise me"
  still showed the result before sending.
- Added a genuine blind send: pick a Temptation, type, and deadline,
  then "🙈 Surprise them" draws randomly from every eligible dare at
  every intensity the Temptation currently allows, and sends it without
  ever showing you which one it was.
- This required fixing something deeper than the UI — the sender could
  already see their own sent dares in full immediately, regardless of
  blind sending, since the reveal logic never distinguished the two
  cases. Fixed the actual reveal rule so a blind-sent dare stays hidden
  from the sender too, until the recipient responds — at which point it
  reveals for both of you together. Tested this directly end to end:
  created a blind dare, confirmed it stored correctly, confirmed the
  sender-visibility fix works as intended.
- The safety guarantees don't change — every draw is still constrained
  by the Temptation's current match tier and intensity cap, and only
  ever pulls from the admin-curated library, exactly as before. This
  only removes the sender's ability to pick a specific one, not any of
  the underlying limits.

## 1.53.0 — the actual root cause of the unresponsive popup, fixed properly

- Traced this all the way through rather than patching the one modal:
  the app checks for things like pending comparison questions on every
  load, and can open a modal at that moment. But the onboarding screens
  (welcome, the six questions, the explainer) bypass the app's normal
  page structure entirely, which is the only place a modal actually gets
  inserted into the page. So a modal could get created and have its
  buttons wired up while the onboarding screens were still showing —
  except there was nothing in the page yet for those buttons to attach
  to. Once onboarding finished and the real page structure finally
  rendered, the modal appeared for the first time, fully stale — only
  the generic "click outside to close" handler (which attaches
  separately, every time) actually worked.
- Fixed at the root: these checks are now suppressed entirely until
  onboarding is genuinely finished, and explicitly triggered the moment
  it completes, so nothing pending gets silently lost either.
- This was the same underlying issue behind the forfeit modal report
  earlier — that one got a narrower fix (event delegation on that one
  modal) rather than this root-cause one, so it's possible it or
  something similar could resurface elsewhere with a modal I haven't
  hardened. Flagging that honestly rather than claiming this is now
  bulletproof everywhere.

## 1.52.0 — the "move" sweep done properly, and a real fix for the testing workflow

- The two "move" mistakes flagged were real, and checking properly
  turned up eleven more, not two — five *inside the database functions
  themselves*, including genuine user-facing error messages ("Move not
  found", "Only the person who sent this move can react to it") that
  would show verbatim if triggered, not just internal text. Fixed all
  five functions (create_dare, complete_dare, respond_to_dare,
  react_to_dare_quality, sign_off_dare) and reverified every grant
  afterward — all still correctly locked down, zero duplicate function
  versions created.
- On the app side, my first sweep used a filter that accidentally hid a
  real bug from itself (excluding any line containing `state.`, which
  also matched a line with the actual mistake in it). Redid it with zero
  exclusions and manually reviewed every hit. Found and fixed five more:
  two notification-matching strings that had to be updated to match the
  now-corrected database text or the celebration/toasts would have
  silently stopped firing, the turn message, a fallback dare title, and
  the Signal hint text.
- Built the actual fix for the real problem — needing to fully recreate
  an account just to preview a screen change. New "Preview my onboarding
  again" button in Account settings, usable by either account on
  themselves: resets your own six answers and your own welcome-screen
  flags, touches nothing else — not your partner's data, not real
  gameplay, no new account or pairing needed. Tested directly against
  Jacki's actual account: her flags reset correctly, Martin's stayed
  completely untouched.

## 1.51.0 — one page explaining the app, seen once, never again

- Scaled back from a multi-screen guided tour to exactly what was asked
  for: a single page, right after finishing the six questions, covering
  all five tabs in one line each, the actual mechanics of how a move
  works (send, respond, complete, points, Heat Meter, rewards), and how
  forfeits work. Shown once ever, then gone for good — same one-time
  pattern as the welcome screen and Step 1 celebration, re-armed by
  Start Again for testing.
- This fills a real, previously-total gap — before this, nothing in the
  app explained the tabs, the dare flow, or what any of the terminology
  meant. It was all assumed.

## 1.50.0 — genuinely more top spacing, gauge explained, a broken question fixed, six-areas preview

- Increased the welcome screen's top padding substantially (48px wasn't
  enough) — should read as clearly more breathing room this time.
- Every wizard question now explains the gauge before you hit it — what
  the scale means and that it's tappable. Previously five icons just
  appeared with zero explanation of what to do with them.
- Fixed a real content bug: the Dominance & Surrender general question
  asked "taking control, giving it up, or switching between the two" —
  a multiple-choice question forced onto a cold-to-hot enthusiasm scale,
  which never fit. Rewrote it to ask how the *idea* of power dynamics
  sounds, which the scale actually measures correctly. The specific
  "which role" question belongs to a specific card later, not the
  general scale.
- Added a genuine new step: after the welcome screen, a preview of all
  six Temptations with a one-line feel for each, before question 1 ever
  appears — so there's a real sense of what's coming rather than being
  dropped straight into it.

## 1.49.2 — the TwoPlay/foreplay wordplay is now actually visible

- Added a short italic line under the title: "(yes — as in foreplay.
  That's rather the idea.)" — the wordplay in the app's own name was
  invisible until pointed out directly; this lets it land without
  over-explaining the joke.

## 1.49.1 — welcome screen spacing and pronoun fixes

- Switched from vertical centering (unpredictable with content this
  long — could crowd the title depending on screen height) to a
  deliberate, fixed top padding, so the spacing is now consistent
  regardless of device.
- Shifted "the two of you" to "us"/"we" throughout the parts describing
  the shared activity ahead — the invite came from a real person, so
  once you're actually in the app, it should read as something you're
  in together, not a description of a couple from outside. Kept the
  opening line ("You got an email...") in "you," since that's genuinely
  about the individual reader's own specific action, not something
  shared — a deliberate shift in voice, not an oversight.

## 1.49.0 — onboarding actually explains itself now

- Found the real source of the generic screenshot text from a few
  messages back: it wasn't stale code, it was database content — all
  six general questions shared one identical, generic explanation
  ("the other cards in this heading get more particular"), which is why
  searching the app's own code for it turned up nothing. Rewrote all six
  individually, each genuinely tailored to its own Temptation, warm
  rather than clinical, and fixed the leftover "heading" wording while
  at it.
- Rewrote the welcome screen with the arc it was missing: acknowledges
  the mysterious email and link she just followed, actually explains
  what TwoPlay is before asking anything of her, then introduces the six
  gentle questions as a first step rather than assuming she already
  knows what any of this means. Previously it jumped straight to
  mechanics ("six quick questions, one for each Temptation") with zero
  context for someone arriving cold.

## 1.48.1 — subject line was missing

- Real gap: pasting into Mail's body never carries a subject line over,
  and I hadn't surfaced one anywhere. Added a suggested subject ("A
  little something's waiting for you…") shown with its own "Copy
  subject" button, right above "Copy email" — copy that into Mail's
  Subject field first, then paste the email into the body.

## 1.48.0 — the app generates and copies the invite email itself

- "Waiting on your partner" now has a "Copy email" button, right below
  the invite link — enter their name (optional), tap it, and the whole
  designed email (with the current invite link already baked in) gets
  copied as fully-formatted rich content, not raw HTML. Paste into a new
  message in Mail and it arrives styled, link and all — no more opening
  a separate file, selecting all, or manually swapping in the link.
- The standalone HTML file from before still works if preferred, but
  this is now the faster path, and the one that can't go stale (the link
  is always the current invite code, generated fresh each time).

## 1.47.0 — shareable invite link, no more typing a code

- Generating an invite code now also shows a full link
  (?invite=XXXXXX) with a "Copy link" button — send that instead of the
  raw code and whoever opens it lands straight on the pairing screen
  with the code already filled in, one tap to join.
- This is the piece needed for the "email them a link" idea to actually
  work end to end — the email-sending itself needs a real email service
  with an API key, which I can't provision myself, but once that's
  connected, this is exactly the link it would send.

## 1.46.1 — theme picker copy fixed

- "Lighter, warmer theme" / "Lighter, cooler theme" were leftover from
  before the dark redesign — fixed in all three places they appeared
  (signup form, the post-signup theme-choice screen, and its buttons).

## 1.46.0 — remove a partner and re-pair fresh

- New Admin danger-zone action: removes your current partner from the
  couple entirely, wipes all gameplay data tied to that pairing (same
  scope as Start Again), and frees the couple back up for a new invite
  code — the existing "Waiting on your partner" screen already handles
  generating and displaying that code, so nothing new was needed there.
- Requires typing your partner's name exactly to confirm, same
  seriousness as the RESET confirmation. Tested directly: Jacki's own
  account is correctly rejected from removing herself.
- This is exactly what you need for testing the startup flow properly —
  remove the test pairing, generate a fresh code, sign up a new test
  account under a different alias of your own email, and walk through
  the whole thing from a genuinely blank slate.

## 1.45.0 — a real welcome before the wizard begins

- Found something worth acting on: the screenshot text you sent doesn't
  match any string in the current codebase — meaning it was almost
  certainly a stale cached copy of the PWA, not what's actually been
  shipped. Worth ruling this out for the earlier "still not working"
  reports too (forfeit modal, CSV export) — try removing the app from
  your home screen and re-adding it fresh.
- Added an actual welcome moment before question 1: a one-time screen
  (shown once ever, re-armed by "Start again" like the Step 1
  celebration) explaining what's about to happen and why, with a preview
  of the gauge you're about to use, before diving into the six questions
  cold.

## 1.44.0 — "Start again" — a proper gameplay reset in Admin

- New danger-zone section at the bottom of Admin: wipes every answer,
  dare, notification, weekly settlement, and Heat Meter progress for
  both accounts, and re-arms the Step 1 completion celebration so it can
  be seen fresh again. Never touches pairing, accounts, or anything
  you've curated — headings, cards, the dare library, forfeits, and
  reward definitions are all untouched (reward *claims* reset, but the
  rewards themselves stay).
- Requires typing "RESET" to confirm — not just a tap-through dialog,
  given how destructive this is. Tested the access control directly:
  Jacki's account is correctly rejected from triggering it at all.
- Also clears two session-only flags (skipped wizard questions, whether
  you've seen the partner teaser) that would otherwise carry over from
  before the reset and interfere with a genuinely fresh simulation.

## 1.43.1 — "Surprise me" for dares too, same as forfeits

- Real fairness gap: whoever's creating a dare could browse every
  library suggestion for a Temptation and cherry-pick whichever one
  benefited them, with nothing forcing genuine unpredictability. Added
  "🎲 Surprise me — pick one at random," positioned above the browsable
  list so using it never requires seeing what else was available —
  mirrors the same mechanic already built for forfeits. Browsing and
  picking intentionally, or writing your own, are both still there for
  when that's genuinely what you want to do.

## 1.43.0 — Rewards into Admin, Dares search/collapse, calendar fix, sender-side waiting status

- **Rewards moved fully into Admin**, matching Questions/Dares/Forfeits
  exactly: add/edit/delete, CSV import, CSV export. Tested directly —
  Jacki's account correctly rejected when trying to add a reward, and
  claiming (which stays open to both) still worked and was verified.
  The Rewards tab is now view-and-claim only.
- Found and fixed a real bug while doing this: a reward's `revealed`
  flag was set to false on creation and never updated anywhere — every
  reward would have stayed "Locked" forever regardless of Heat Meter
  progress. Now computed live from your current heat instead of a stale
  stored flag.
- **Dares tab**: added "Done by you" alongside "Sent by you" — both now
  collapsible (collapsed by default) with their own search box, reusing
  the same focus-safe search pattern from Admin so typing in one doesn't
  steal focus from the other.
- **Forfeit modal hardened** with event delegation instead of direct
  element lookups, and the forfeit CSV export was reviewed line-by-line
  against the working Dares/Questions pattern with no difference found —
  if either is still broken after this, it's very likely the PWA serving
  a cached older version; try a hard refresh or removing and re-adding
  the home screen icon.
- **Deadline picker**: found a likely real cause — Chromium's native
  calendar icon renders dark by default and was going invisible against
  the new dark theme. Added a fix to invert it for visibility. iOS
  Safari's picker doesn't use a separate icon so should be unaffected
  either way.
- **Sender-side waiting status**: Playroom now shows "Waiting On
  [partner]" for dares you've sent that haven't been responded to yet —
  previously only the recipient got any status banner at all.

## 1.42.2 — fixed deleting a forfeit, and a real mistake caught along the way

- Deleting a forfeit that had ever been picked for a settled week was
  blocked by a foreign key I'd never actually configured a delete
  behavior for — Postgres defaulted to blocking it entirely. Fixed: the
  settlement already snapshots the forfeit's title and instructions at
  pick-time specifically for this reason, so the link can now safely go
  null on deletion while the historical record stays completely intact.
- Testing that fix surfaced a second real bug: three places in the app
  checked `forfeit_id` to mean "has a forfeit been picked," which breaks
  the moment that id can legitimately go null. All three now check the
  permanent `forfeit_title` snapshot instead.
- Own a mistake made while testing this: the fix was verified against
  your actual "They Set the Pace" entry instead of a disposable test row,
  which deleted real content rather than a throwaway. Recovered the exact
  title and instructions from the settlement's snapshot, and restored it
  properly once you confirmed the Temptation and intensity it had been
  set to. Re-tested the same fix afterward against a genuine throwaway
  entry, which is what should have happened the first time.

## 1.42.1 — you can now actually see what a forfeit asks of you

- The forfeit's full instructions were being stored correctly the whole
  time, just never displayed — the Playroom banner only ever showed the
  title. Tapping it now opens the actual details, with "Mark it done"
  living there instead of floating on the summary line with nothing to
  read first.

## 1.42.0 — the three flagged gaps, all fixed

- Notifications rewritten as a proper queue instead of only checking for
  one message type: "accepted" now shows a toast, "reaction received"
  shows a toast with the bonus amount, and completion still gets the full
  celebration. Added a generic fallback too — any future notification
  type that isn't explicitly handled now shows as a plain toast instead
  of silently vanishing, which is exactly the class of bug this was.
  Cleared out 9 stale unread notifications from earlier testing first, so
  this shows up clean going forward rather than dumping old test noise.
- Added 4 starter rewards at 25/50/75/100% Heat Meter, so there's
  actually something to unlock now — this was a fully working feature
  that just had nothing in it.
- Added weekly results to the History tab — every settled week is now
  visible (who won, the score, the forfeit and whether it's done), not
  just the single most recent one on Playroom.

## 1.41.0 — forfeit picker now has an actual "which pool" moment

- Picking a forfeit was one flat mixed list before, so there was no real
  jeopardy to it. Now it's two steps: first choose **Everyday** or
  **Risqué** (with counts shown for each, nothing else), then either
  browse titles within that pool or hit "🎲 Surprise me" to draw one at
  random instead of cherry-picking. The pool choice is the real moment of
  jeopardy; the random-draw option adds a second layer if you want it.
- Intimate forfeits are still filtered to what's currently open before
  they ever show up in the Risqué pool — nothing changes about the
  underlying safety rule, just how the choice is presented.

## 1.40.0 — full dark redesign, all three themes

- Replaced the light pastel palette (cream/pale pink/pale blue) with
  near-black backgrounds across all three themes — the default, and both
  gendered variants. Each theme keeps its own accent identity, just
  bolder and richer: default is deep red and gold, the rose theme is a
  vivid magenta-red, the blue theme is a saturated cool blue — all
  against near-black surfaces instead of white cards on a pale
  background.
- Swept the whole file for hardcoded colors that weren't using the theme
  system and would've clashed against dark backgrounds: the intensity
  pills (Tease/Risqué/Bold/Wild) and the Perfect Match tier pill were both
  pale pastels designed for white cards — redesigned as dark, saturated
  chips with light text so they read as rich rather than washed out.
  Checked the answer gauge and confetti colors too; both were already
  vivid enough to work fine on dark and needed no change.
- Updated the browser status bar color to match the new dark background.

## 1.39.0 — export to CSV for Questions, Dares, and Forfeits

- Added "Export to CSV" for all three admin sections, each producing a
  file in exactly the same format its own import expects — round-trip
  editing with Grok is now: export, hand the file over for revisions,
  re-import the result.
- Added forfeit-library-template.csv, matching the same starter-template
  pattern as the boundary card and dare library templates.
- Caught and fixed a mistake in my own draft template before shipping —
  an example forfeit described the partner picking your next dare, which
  directly contradicts the loser-always-picks-their-own design. Replaced
  it with an example that's actually consistent with how it works.

## 1.38.2 — realtime actually works now, and confetti gets to breathe

- Found and fixed a real, significant bug: the three tables the app's
  realtime subscriptions depend on (dares, notifications, rewards) were
  never added to the database's actual realtime publication. The
  JavaScript subscription code was correct the whole time, but the
  database was never configured to broadcast changes for it to receive —
  so nothing has ever updated live until now. Verified directly that all
  three tables are now properly registered.
- Delayed the "Dare Complete!" card by 1.4 seconds after the confetti
  fires, so the burst is actually visible before the dark overlay covers
  the screen — previously they appeared at the same instant and the
  confetti was hidden behind the card immediately.

## 1.38.1 — closed the loose dares update policy

- Removed the broad database policy that let either partner directly
  update any field on a dare via a raw table call. Verified the fix by
  actually trying the exploit before and after: attempting to set
  `points_awarded` to 999999 and status to completed directly succeeded
  silently before this change and is now fully blocked (the row stays
  untouched). Confirmed the legitimate path still works exactly as
  before — completing a dare through the app still awards points
  correctly. No app-side change needed; this was purely a database fix.

## 1.38.0 — weekly forfeits, and images on dares

- Built the weekly forfeit system discussed: a live "this week" score
  separate from the lifetime total, settled once a week has genuinely
  ended. Tested directly against the database — settling twice in a row
  correctly created only one record, the winner was rejected trying to
  pick the loser's forfeit for them, and an intimate forfeit above what a
  Temptation currently allows was correctly rejected too.
- The loser always picks their own forfeit — never imposed by the winner,
  matching the same principle behind quality bonuses and sign-off.
  Intimate forfeits are capped by that Temptation's current intensity,
  same rule as every dare.
- Admin gets a new Forfeits section — add one at a time or import a CSV,
  same pattern as Dares and Questions.
- Added images to dares: library dares can now have one (with a preview
  when editing), and creating a dare either inherits the picked library
  dare's image automatically or lets you attach your own — shown right on
  the dare card once it's revealed.
- While building this, found a broad pre-existing database policy that
  lets either partner directly update any field on a dare via a raw table
  call, not just through the safe functions. Didn't touch it or rely on
  it for this feature, but it's worth tightening separately.

## 1.37.3 — remaining "Move" text renamed to "Dare"

- "Create a move" → "Create a dare," plus 13 other leftover mentions
  (celebration title, in-play banner, turn message, counter modal,
  toasts, empty states) — all now say Dare, matching the tab rename from
  a while back.
- Bonus catch while sweeping for these: the login screen's big title
  still said "Moves" from before the app was renamed to TwoPlay — fixed
  that too.
- Left "which way you moved it" alone — that's a different meaning
  entirely (moving a gauge slider), not the Dare feature.

## 1.37.2 — replaced remaining "your partner"/"them" with actual names

- Most of the app already used real names (the wizard, teaser screen, and
  turn message all did from the start) — found and fixed the three spots
  that still said "your partner" or "them": the comparison question
  prompt, the Signal number hint in Account settings, and the in-play
  hero's "waiting on them" line. All three now show the actual name when
  it's known.
- Left a few "your partner" mentions alone on purpose — the ones on the
  signup and pairing screens, since those happen before you're actually
  paired and there's no name to use yet.

## 1.37.1 — Zones renamed to Temptations

- "Zones" renamed to "Temptations" everywhere it appears — same 37
  places just updated for "Zones," done the same careful way (checked the
  count matched exactly before and after, so nothing was missed or
  double-changed). CSV import now also accepts a "temptation" column
  header alongside "category" and "zone."

## 1.37.0 — genuine two-sided comparison loop, renamed scale, Zones

- The 5-tier answer scale has new names: All In, Keen, Curious, If You're
  Up For It, Not For Me (was Full Spark, Warming Up, Blushing Yes, Just
  For You, Cold Card). Same gauge, same underlying values — just better
  words. Checked the whole app for leftover hardcoded mentions of the old
  names; none left.
- "Headings" renamed to "Zones" everywhere it's shown to you — button
  labels, hint text, error messages, CSV import instructions (which now
  also accepts "zone" as a column header, not just "category"). Internal
  code names are unchanged; this was purely about what you see.
- Built the actual two-sided comparison loop this was all missing: when
  one of you answers a follow-up question after completing a dare, the
  other partner now gets invited to answer that exact same question —
  live if the app's open, or the next time they open it. Verified this
  directly against the database: Jacki's answered card showed up
  correctly as "pending comparison" for Martin before this was built,
  and now it surfaces as an actual prompt instead of sitting invisible.
- This is what makes a Zone's picture genuinely mutual instead of
  one-sided — whoever completes more dares doesn't get to unilaterally
  shape where a Zone lands; both of you have to weigh in on the same
  cards for them to count.

## 1.36.0 — real fanfare, and a genuine notification bug fixed

- Found and fixed the actual cause of "no notification at all": the app
  was writing "Your move was completed" notifications to the database
  correctly the whole time, but nothing in the interface ever displayed
  them. That's fixed now, not just made more exciting.
- Completing a move now triggers real confetti and a big "Move Complete!"
  card showing who did it, points earned (including any bonus), and the
  Heat Meter gain — replacing the quiet toast that was easy to miss.
- The sender gets the same celebration — live, immediately, if the app is
  open when it happens; otherwise the next time they open it. Either way,
  it's now impossible to complete a move and have your partner never find
  out.

## 1.35.1 — app renamed to TwoPlay

- The app itself is now called "TwoPlay" (browser tab, home screen icon,
  the header brand mark) — "Playroom" stays as the name of the first tab,
  same relationship as "Kinks" and "Dares" being tab names under the app,
  not the app itself.

## 1.35.0 — app renamed to Playroom, identity moved into the header

- Renamed the app itself from "Moves" to "Playroom" — the browser tab
  title, home screen icon name, and the small brand mark in the top-right
  corner all reflect this now.
- Your photo and name now live in the header, visible from every screen,
  not just Home — tap them anytime to open your account.
- New shared "Your account" screen (tap your name/photo in the header) —
  change your photo, your name, and your Signal number, all in one place.
  Available equally to both accounts, since none of this is a
  content-management function — it's just your own details. The separate
  Admin tab (Questions & Dares) stays exactly as restricted as before.
- Playroom's body no longer repeats your photo and name, since they're
  always visible in the header now — one less duplicated thing on screen.
- Cleaned up a stale dark-mode browser color left over from the very
  first version, before the light themes existed.

## 1.34.1 — Home renamed to Playroom

- "Heat" renamed to "Playroom" — same slim screen, just a name that
  actually reads as a place rather than a stat.

## 1.34.0 — Home slimmed to a real summary, tabs renamed and reordered

- Renamed and reordered tabs: Heat (was Home) is now first, then Kinks,
  Dares (was Moves), Rewards, History.
- Home ("Heat") no longer duplicates the full dare lists — it's now: the
  in-play hero if something's active, an equally visible nudge if
  something's waiting on your response, a calm "you're all caught up"
  otherwise, your welcome/avatar/Signal number, the scoreboard, the Heat
  Meter, and "Create a move." One screen, one job: what's happening right
  now, how are we doing overall.
- The Dares tab now properly holds what moved off Home: New for you, In
  play, and Sent by you — the full interactive cards with Accept/Decline/
  Counter/Mark Complete live there, where a dedicated tab actually makes
  sense for them.
- "Recent" dropped entirely — History already covers completed moves, no
  need for the same thing in two places.

## 1.33.0 — an in-play move you actually can't miss

- The small banner and 12px countdown from last time weren't enough —
  fixed properly. There's now a full-width, wine-to-gold banner at the
  very top of Home, above even the welcome greeting, whenever a move is
  in play: the dare's title, a large 38px countdown, and whose move it is
  to act on. If more than one move is active, the most urgent (soonest
  deadline) leads, with a note about how many others are running.

## 1.32.0 — one-tap Signal link on in-play moves

- Added a place to save your own Signal number, under your name on Home
  ("Add your Signal number"). Your partner's number is visible to you
  specifically so the app can build a link to message them — not shown
  anywhere else, and this isn't the same as any of the boundary-answer
  privacy, since it's contact info you're sharing with each other on
  purpose.
- In-play moves now show "Message on Signal →" whenever your partner's
  number is saved — opens straight to your Signal chat with them, no
  searching. Only appears once both the move is active and their number
  is known; Martin's number is saved already, Jacki's still needs adding
  before his own outbound link works.

## 1.31.0 — accepted moves actually feel "in play"

- An accepted (or countered/in-progress) move now gets a warm gold glow, a
  pulsing "In Play" indicator, and — if it has a deadline — a live
  countdown ("2h 14m left") that actually ticks down while the app is
  open, on both the sender's and recipient's screens. Replaces the small
  status badge that was easy to miss.
- The countdown updates every 30 seconds without needing new data, and
  deliberately pauses while any modal is open so it never yanks focus out
  from under someone mid-form.
- Deliberately did not build live chat or a "during the dare" experience
  into the app — that's what Signal is for, matching the "not a
  replacement for a private messaging app" principle from the original
  brief.

## 1.30.0 — evidence photos, sign-off, and the admin alignment fixed for real

- Evidence photos can now be attached in-app when marking a move
  complete — optional, private, locked to that specific dare (its own
  storage bucket, RLS restricted to your couple only). Worth repeating:
  this is private from other people, not end-to-end encrypted the way
  Signal is — a deliberate trade-off you made with that understood.
- "Requires my confirmation to count as complete" — captured since the
  very first version but never actually wired up — now does something:
  the sender gets a "Sign off as complete" button once the recipient
  marks it done. Points are unaffected either way; this is purely a
  closure step, never a gate.
- Fixed the Admin column misalignment properly this time — the actual
  cause was the Questions heading text being longer than the Dares one
  and wrapping to a second line. Both now read almost character-for-
  character the same length, so they wrap identically regardless of
  screen width.

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
