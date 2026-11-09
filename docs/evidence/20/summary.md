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

- In the implementer's run on the Pixel 7, the photo screen showed the text ML Kit read. The before-fix and after-fix photo-screen screenshots were removed from the branch because they showed a person. The after-fix proof is Nam's own real-paper read on the Pixel 7, to be added here.
- The log of the fixed run had no `ComponentDiscovery`, `google_mlkit_text_recognizer` or `AndroidRuntime` lines. Its one `NullPointerException` is in the phone's launcher (`AppTaskStateSource`), not the app.
