# Backlog

Tickets we expect to need, in order. Each one goes through `/refine` (discuss, split, acceptance criteria), then `/ticket` (post to GitHub).
This list is a starting guess: `/refine` may split, merge or change items.

**Status values:** not refined · refined · posted (#issue) · done

## Phase 1: the reading gate

Goal: prove the app can read a ticket from a photo before building the rest.

| # | Ticket | Needs from Nam | Status |
|---|---|---|---|
| 1 | Create the Flutter app (empty app on the pinned Flutter version) and write `docs/CONVENTIONS.md` | Flutter installed (`./setup.sh`) | done (#1, #2) |
| 2 | Home screen with the "Quét vé" button (sketch 1) | — | not refined |
| 3 | The button opens the camera; tapping the shutter takes the photo (sketch 2) | — | not refined |
| 4 | Show the taken photo on screen | — | not refined |
| 5 | Mark where each field sits on the ticket (ticket number, date, province), per province if layouts differ | The three ticket photos, and which area holds which field | not refined |
| 6 | Read the three fields from those areas; check against the three saved photos | The correct values for the three photos | not refined |
| 7 | Show what was read on a temporary screen (ticket number, date, province) | — | not refined |

**Go / no-go:** all three fields read correctly on the three saved photos **and** when scanning real tickets through the app. If no-go, stop and rethink (another library, native app, or another option).

## Phase 2: after the gate (only if go)

| # | Ticket | Needs from Nam | Status |
|---|---|---|---|
| 8 | Find a free source for the official miền Nam winning results | — | not refined |
| 9 | Check a read ticket against the results (won, lost, or not drawn yet) | — | not refined |
| 10 | Result screens: won with celebration, lost with animation, not drawn yet, can't read (sketches 4a–4d) | — | not refined |

## Built along the way

The ticket workflow pieces ([WORKFLOW.md](WORKFLOW.md)) get built when the first ticket needs them, not as separate tickets up front: the `/work` skill, the test writer, implementer and reviewer agents, the test hook, and CI.
