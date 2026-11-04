# Backlog

Tickets we expect to need, in order. Each one goes through `/refine` (discuss, split, acceptance criteria), then `/ticket` (post to GitHub).
This list is a starting guess: `/refine` may split, merge or change items.

**Status values:** not refined · refined · posted (#issue) · done

## Phase 1: the reading gate

Goal: prove the app can read a ticket from a photo before building the rest.

| # | Ticket | Needs from Nam | Status |
|---|---|---|---|
| 1 | Create the Flutter app (empty app on the pinned Flutter version) and write `docs/CONVENTIONS.md` | Flutter installed (`./setup.sh`) | done (#1, #2) |
| 2 | Home screen with the "Quét vé" button (sketch 1) | — | #4 home screen done; #5 portrait lock done (PR #7) |
| 3 | The button opens the camera; tapping the shutter takes the photo (sketch 2) | — | #8 take the photo done (PR #11); #9 camera refused posted |
| 4 | Show the taken photo on screen | — | posted (#10) |
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

## Found along the way

Items noticed during other work. They go through `/refine` like everything else.

| # | Ticket | Needs from Nam | Status |
|---|---|---|---|
| 11 | Change the home button text: the person takes a photo of the ticket, so "Quét vé" (scan ticket) should say something like "Chụp ảnh vé". Update sketch 1 in `docs/design/` too, since screens must follow the sketches. | The exact wording | not refined |
| 12 | Delete a ticket's proof of testing (`docs/evidence/<issue>/`) once the ticket is closed and its branch deleted | — | not refined |
| 13 | `/work` runs integration tests with one command, but #5's tests need `fvm flutter drive` and #4's need their file path. Make `/work` find and run every kind (found in #5) | — | not refined |
| 14 | Manual steps say "click the emulator toolbar" and "take a Mac screenshot", which Claude can't do. Write them with `adb emu rotate` and `adb emu screenrecord screenshot`, which work. Note that `adb emu rotate` only turns one way (found in #5) | — | not refined |
| 15 | The status bar's clock and icons are dark on the dark camera screen, so they're hard to read. The sketch doesn't cover this (found in #8) | — | not refined |
| 16 | Leaving the app from the camera screen (Home, locking the phone, a call) and coming back isn't tested. The camera add-on's guide says the app must handle this, and its Android code probably does (found in #8) | — | not refined |
| 17 | Failure cases: a failed photo leaves the shutter dead, a phone with no camera leaves "Quét vé" dead, and an app killed during a save can leave `ticket_photo_staged.jpg` behind until the next photo (found in #8) | — | not refined |
| 18 | The app sets no backup rule, so kept ticket photos may go into the person's Google backup. Not checked on the phone. Decide whether they should (found in #8) | Whether photos may be backed up | not refined |
| 19 | Tapping "Quét vé" just after leaving the camera might open a camera screen with no picture, because the old camera's cleanup isn't waited for. Found by reading the add-on's code, not seen running (found in #8) | — | not refined |
| 20 | Out-of-date notes: `README.md` says there's no Android test phone; `docs/tests/8.md` and the home screen test names say `Pixel_10`; `docs/tests/8.md` should say `adb -s <serial>` when two devices are connected; the header in `phone.dart` mentions only the emulator; `docs/tests/4.md` lists tests removed in #8 (found in #8) | — | not refined |
| 21 | Make `/work` and the reviewer match Nam's decisions in #8: test on the Pixel 7 (portrait lock tests stay on the emulator), and `/work`, not the reviewer, checks the evidence link once the pull request is open. Also decide how `/work` gets the person holding the phone during a run (found in #8) | — | not refined |
| 22 | The camera tests need a moving picture: a steady hand can fail a run, they can't run unattended, and they can't pass on `Pixel_10`. Decide how to fix this before designing CI (found in #8) | — | not refined |
| 23 | Test gaps: no automated test presses back during a save, and the "only the new photo" test would miss a second copy of the new photo. Neither fails today (found in #8) | — | not refined |
| 24 | Small cleanups: `camera_driver.dart` repeats the home screen texts from `home_screen_checks.dart`, and the built app includes `ACCESS_NETWORK_STATE`, a normal permission the app doesn't ask for itself, from an unconfirmed add-on (found in #8) | — | not refined |

## Built along the way

The ticket workflow pieces ([WORKFLOW.md](WORKFLOW.md)) get built when the first ticket needs them, not as separate tickets up front: the `/work` skill, the test writer, implementer and reviewer agents, the test hook, and CI.
