# Ticket #20: release build can't read tickets

All runs on Nam's Pixel 7 (release APK, installed with adb). The photo was taken by tapping the camera and shutter through adb, so these runs are the implementer's repro, not Nam's real-paper proof.

## Cause

R8 removed the no-argument constructor of ML Kit's component registrars (`CommonComponentRegistrar`, `VisionCommonRegistrar`, `TextRegistrar`). ML Kit creates them by name at start-up, so it started with no components. The first read then found no `SharedPrefManager`, and `InputImage.fromFilePath` crashed with a `NullPointerException`. It was not the internet permission.

## How it was found

- `before-fix-release-crash.log`, `before-fix-stack-retraced.txt`: the crash on a release build of `main`, and its stack traced back with R8's `mapping.txt`. It ends in `InputImage.fromFilePath`, in ML Kit's `vision-common` library.
- `internet-permission-on-still-crashes.log`: same crash with the INTERNET permission put back (the installed app listed it). Start-up logged `ComponentDiscovery: Could not instantiate ...CommonComponentRegistrar` (`NoSuchMethodException: <init> []`). So the permission is not the cause.
- Release build with R8 off (`isMinifyEnabled = false`): no crash. So it is R8.
- Keep rules tried with R8 on: `com.google.mlkit.**` fixed it. `mlkit.common.**` alone did not, and neither did `mlkit.vision.common.**` or `mlkit.vision.text.internal.**`, because the three registrars are in different packages. Keeping the registrars' constructors fixed it.

## Fix

`app/android/app/proguard-rules.pro`: keep the no-argument constructor of every class implementing `com.google.firebase.components.ComponentRegistrar`. The INTERNET permission stays removed.

## After the fix

- In the implementer's run on the Pixel 7, the photo screen showed the text ML Kit read. The before-fix and after-fix photo-screen screenshots were removed from the branch because they showed a person. The implementer's after-fix log wasn't saved; the saved proof is Nam's read below.
- The log of the implementer's fixed run had no `ComponentDiscovery`, `google_mlkit_text_recognizer` or `AndroidRuntime` lines. Its one `NullPointerException` is in the phone's launcher (`AppTaskStateSource`), not the app.

## Nam's real-paper read (the ticket's proof)

Run by `/work` on 2026-11-09, on Nam's Pixel 7. The app was uninstalled, then the release APK built from `ticket-20-release-read` was installed fresh (it lists no INTERNET permission). The phone's log was cleared, then recorded while Nam opened the app, tapped "Quét vé" and photographed a real Bạc Liêu paper ticket by hand. The screenshot was taken over adb once the text was on screen.

- `real-ticket-release-pixel7.png`: the photo screen shows the text ML Kit read (for example `871723`, `LOẠI T10-K3 C`, `MỞ NGÀY THỨ BA`, `20-10-2026O`), not "Không đọc được vé". **Edited:** the part of the photo below the ticket is blacked out because it showed a person. The ticket and all of the text under the photo are untouched.
- `real-ticket-release-pixel7-log.txt`: the app's own log lines from that read (other apps' lines left out for privacy). No `ComponentDiscovery`, `AndroidRuntime`, `FATAL` or `google_mlkit` error lines; ML Kit's text models load at 20:20:33 and the read completes. The `E/` lines are the camera closing its buffers after the shutter. The full log also had one `NullPointerException` in another process (pid 3025, the phone's launcher), not the app.
- The internet permission was not put back, so the airplane-mode read doesn't apply.
- `analyze.txt`, `widget-tests.txt`: `fvm flutter analyze` (no issues) and the 6 widget tests (all passed), run on the Mac. No integration tests: the ticket has none, and the change only affects release builds.
