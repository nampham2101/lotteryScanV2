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
| 3 | The button opens the camera; tapping the shutter takes the photo (sketch 2) | — | #8 take the photo done (PR #11); #9 camera refused done (PR #12) |
| 4 | Show the taken photo on screen | — | done (#10, PR #13) |
| 5 | Mark where each field sits on the ticket (ticket number, date, province), per province if layouts differ | The three ticket photos, and which area holds which field | done (#14, PR #15) |
| 6 | Read the three fields from those areas; check against the four saved photos. Split: the first part, seeing what ML Kit reads on the photos, is #16; the rest gets refined after its results | The correct values for the four photos | not refined (split, first part #16) |
| 7 | Show what was read on a temporary screen (ticket number, date, province) | — | not refined |

**Go / no-go:** all three fields read correctly on the four saved photos **and** when scanning real tickets through the app. If no-go, stop and rethink (another library, native app, or another option).

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
| 20 | Out-of-date notes: `docs/tests/8.md` and the home screen test names say `Pixel_10`; `docs/tests/8.md` should say `adb -s <serial>` when two devices are connected; the header in `phone.dart` mentions only the emulator; `docs/tests/4.md` lists tests removed in #8 (found in #8) | — | not refined |
| 21 | Make `/work` and the reviewer match Nam's decision in #8: `/work`, not the reviewer, checks the evidence link once the pull request is open. Also decide how `/work` gets the person holding the phone during a run (found in #8) | — | not refined |
| 22 | The camera tests need a moving picture: a steady hand can fail a run, they can't run unattended, and they can't pass on `Pixel_10`. Decide how to fix this before designing CI (found in #8) | — | not refined |
| 23 | Test gaps: no automated test presses back during a save, and the "only the new photo" test would miss a second copy of the new photo. Neither fails today (found in #8) | — | not refined |
| 24 | Small cleanups: `camera_driver.dart` repeats the home screen texts from `home_screen_checks.dart`, and the built app includes `ACCESS_NETWORK_STATE`, a normal permission the app doesn't ask for itself, from an unconfirmed add-on (found in #8) | — | not refined |
| 25 | The camera refused pop-up from #9 only has "Đóng", so the person must leave the app and find the phone's Settings themselves. Add a button that opens the app's page in Settings, so they can allow the camera from there. #9 left this out on purpose (found by Nam in #9) | The button's wording, and whether the sketches need a pop-up | not refined |
| 26 | A comment in `ticket_camera.dart` says `CameraAccessDeniedWithoutPrompt` is what Android gives when it won't ask again. The Android add-on only ever sends `CameraAccessDenied`; that code and `CameraAccessRestricted` come from iOS. The app behaves correctly. Fix the comment, and drop the two iOS codes or label them iOS-only (found in #9) | — | not refined |
| 27 | The pop-up doesn't use the app's colours: the app sets no theme, so "Đóng" is Flutter's default purple on lilac, while the app's button is blue. #9 has no sketch for it (found in #9) | Whether the pop-up should match the app | not refined |
| 28 | Screen readers hear English on the pop-up: the app has no Vietnamese language pack, so the area around it is announced as "Dismiss". Any later Flutter pop-up will have the same gap (found in #9) | — | not refined |
| 29 | Small test cleanups: `isCameraRefusedForGood` repeats the parsing in `cameraAccess`, `_tapOnScreen` repeats the screen dump and search used by `permissionQuestion` and `_screenItem`, and the "was Android asked" watch in `camera_driver.dart` could use `watchAfterTap` (found in #9) | — | not refined |
| 30 | Out-of-date notes: `WORKFLOW.md` says 11 of #8's 12 camera tests passed on the emulator, but today 4 passed on #9's branch and 3 on `main`, because of the still picture (all 12 pass on the Pixel 7). `docs/tests/8.md`'s file list doesn't mention `driven_app.dart` (found in #9) | — | not refined |
| 31 | The ticket doesn't say what should happen when the person presses back on Android's camera question, so it isn't tested (found in #9) | What should happen | not refined |
| 32 | The evidence checklist says "every test run, passed or failed", but agents' side runs aren't saved. In #9 these were the test writer's runs against a temporary stand-in pop-up, its #8 comparison on the emulator, and the implementer's stopped #8 run. In #10 it was the test writer's runs against a throwaway photo screen, including the wrong versions its tests caught. Decide what "every run" covers, then match the checklist or the agents (found in #9) | What "every run" should cover | not refined |
| 33 | Out-of-date notes: `docs/tests/8.md` still expects home after the shutter, in its coverage table and manual step, and names a test that was renamed. Anyone following that step would see a false failure. The test writer's path rule doesn't let it edit an older ticket's test doc (found in #10) | — | not refined |
| 34 | Test gaps: the pinch and double-tap tests confirm the fingers reached the app, but not that a pinch really slid or that two taps were close enough to count. Nothing presses back while the photo is being read, or checks that Android reports the camera released once the photo screen opens. None of these fails today (found in #10) | — | not refined |
| 35 | The photo screen doesn't keep clear of the phone's status and navigation bars. On a phone whose screen is close to the photo's shape, they would cover its top and bottom edges. Taller screens like the Pixel 7's aren't affected (found in #10) | — | not refined |
| 36 | Small cleanup: `keepStagedTicketPhoto` returns the kept file, but nothing has used that value since #10's fix (found in #10) | — | not refined |
| 37 | Saved test output is mostly camera logging, about 5,000 lines for one run. Save a filtered copy so the proof is easy to read (found in #10) | — | not refined |
| 38 | `adb emu rotate` gives the emulator's camera a second view, so tests get two different photos with nobody holding a phone. Check whether this also solves item 22 before designing CI (found in #10) | — | not refined |
| 39 | `/work` gaps seen in #10: its checks step ticks the boxes before the pull request exists, but the evidence item needs the pull request's link, so the box was ticked once the pull request was open. The test writer can't save its fix-round runs in `docs/evidence/<issue>/`, so `/work` copied that run in by hand (found in #10) | — | not refined |
| 40 | Item 6 and the go / no-go line still say "the three saved photos", but the gate is now four photos and they aren't saved in the project. When refining item 6, fix that wording and include the rule's sideways-copy exception from `docs/TICKET-READING.md` (found in #14) | — | not refined |
| 41 | Reading risks for item 6 that `docs/TICKET-READING.md` doesn't list. Bạc Liêu has tiny digits beside and inside its big digits, and its outline digits could turn IMG_5902 into 3, 3, 2, 2, 7, 7 reading right to left. Long An's small date prints across its big digits, could read as eight digits without its dashes, and its right edge has stamp digits. Vĩnh Long's "2.000.000.000đ" is in the band if the big number is missed. Each of these should end in "Sorry, can you try again?" rather than a wrong result (found in #14) | — | not refined |
| 42 | The area sizes have thin margins: about 2 points on the top area and 3 on the bottom band, about the same as the by-eye measuring. Treat 20% and 35% as starting values and recheck them on more tickets (found in #14) | — | not refined |
| 43 | Small wording fixes in `docs/TICKET-READING.md`. The height note says each share uses the height at that spot, but the table has one top and bottom per photo, which moves shares by about 2 points without changing a conclusion. The sideways rule calls these copies "large", but Long An's left copy is about half the big number's height (found in #14) | — | not refined |
| 44 | The README's list of docs doesn't include `docs/TICKET-READING.md` or `docs/tests` (found in #14) | — | not refined |

## Built along the way

The ticket workflow pieces ([WORKFLOW.md](WORKFLOW.md)) get built when the first ticket needs them, not as separate tickets up front: the `/work` skill, the test writer, implementer and reviewer agents, the test hook, and CI.
