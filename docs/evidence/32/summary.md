# Evidence for #32: the celebration on 4a and the wink on 4b

All runs in this folder, passed or failed. Device for each: widget tests on the Mac (no device), integration tests and recordings on the `Pixel_10` emulator (`emulator-5554`, screen 1080 × 2340). No test needed the Pixel 7.

## Runs

| File | Who ran it | What | Result |
|---|---|---|---|
| `first-run.txt` | test writer | new tests before the feature (Mac, `Pixel_10`), and the 3 updated #31 tests | new tests fail on the missing movement; the 4 "nothing moves" widget tests and the 3 updated #31 tests pass |
| `movement-run.txt` | implementer | #32's 7 integration tests, first build (`Pixel_10`) | 4 failed: the confetti's layer link made the app's screen reader see the card text missing. Fixed in `96b5935` |
| `movement-run-2.txt` | implementer | #32's 7 integration tests after the fix (`Pixel_10`) | all 7 passed |
| `older-31-run.txt` | implementer | the 3 updated #31 tests (`Pixel_10`) | all 3 passed |
| `analyze.txt`, `widget-tests.txt` | implementer | analyze, all widget tests (Mac) | no issues; 28 passed |
| `work-analyze.txt`, `work-widget-tests.txt` | `/work` | analyze, all widget tests (Mac) | no issues; 28 passed |
| `work-movement-run.txt` | `/work` | #32's 7 integration tests (`Pixel_10`) | all 7 passed |
| `work-older-31-run.txt` | `/work` | the 3 updated #31 tests (`Pixel_10`) | all 3 passed |

The test writer's fix `cf32d91` (a failure message that crashed when the screen was correctly still) came before the implementer's first commit, with Nam's yes. It wasn't a review fix round.

## Manual steps (`docs/tests/32.md`)

Recordings `4a-one-prize.mp4`, `4a-two-prizes.mp4` and `4b.mp4` are from `Pixel_10`. Screenshots are frames from them.

| Step | Screenshot | Seen |
|---|---|---|
| 1. 4a, one prize | `4a-confetti-burst.png`, `4a-confetti-falling.png` | the icon, "Chúc mừng!" and "100.000đ" pop in in turn; confetti spreads from the icon and falls to near the bottom of the screen |
| 2. 4a, two prizes | `4a-two-prizes-popping.png` (frame at 2.20 s, taken by `/work`) | "400.000đ" has popped in and "100.000đ" isn't shown yet; one confetti burst |
| 3. 4b | `4b-wink.png` | the smiley is slightly larger with its right eye closed; nothing else moves |

After the movement, 4a and 4b match sketches 4a and 4b in `docs/design/screens.png`, and the integration tests show them pixel-equal to #31's saved screenshots.

## "Done when" → proof

| Criterion | Proof |
|---|---|
| One prize: pop in one after another with a bounce, confetti for about 2 s, then still as in #31 | widget `4a, one prize` (both tests) in `work-widget-tests.txt`; `Once the movement has ended … 4a` in `work-movement-run.txt`; manual step 1 |
| Several prizes: icon and "Chúc mừng!", then each amount, confetti once | widget `4a, several prizes`; `Once the movement has ended … 4a (two prizes)`; manual step 2 |
| Doesn't play again | widget `4a, played once` (60 s); the two 4a `Once the movement has ended` tests (10 s) |
| 4b: about 0.5 s later the smiley grows and winks once, then still as in #31 | widget `4b`; `Once the movement has ended … 4b`; manual step 3 for the wink |
| "Quét vé khác" and back work straight away mid-movement on 4a and 4b | the four `Pressing while it moves` tests in `work-movement-run.txt` |
| Nothing moves on 4c, "too old", "couldn't load", 4d | the four `Nothing moves on the other answer screens` widget tests |
