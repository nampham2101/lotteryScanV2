# Commands used (ticket #16)

All run from the repo root, on the Mac. The emulator is `Pixel_10` (adb serial `emulator-5554`). A Pixel 7 was also plugged in; every adb command names the serial, and the phone was not used.

## 1. Convert the photos

`sips` and `convert` were not used for the final files. A Swift script (below) reads each HEIC, turns the pixels upright, and writes a JPG with no metadata but the colour profile. (A first try with `sips -s format jpeg` was thrown away: it kept the picture sideways with a "turn me" note.)

```
swiftc -o conv conv.swift
./conv ~/Downloads/IMG_5902.HEIC docs/photos/IMG_5902.jpg
./conv ~/Downloads/IMG_5903.HEIC docs/photos/IMG_5903.jpg
./conv "~/Downloads/IMG_5904 2.HEIC" docs/photos/IMG_5904.jpg
./conv ~/Downloads/IMG_5905.HEIC docs/photos/IMG_5905.jpg
cp <the only copy of the Đà Lạt picture> docs/photos/dalat.jpg   # copied as it is, 520x252
```

conv.swift:

```swift
import Foundation
import ImageIO
import UniformTypeIdentifiers
let a = CommandLine.arguments
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
  kCGImageSourceCreateThumbnailWithTransform: true,
  kCGImageSourceThumbnailMaxPixelSize: 10000]
let img = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)!
let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dst, img, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
CGImageDestinationFinalize(dst)
print(img.width, img.height)
```

Pixel sizes of the HEIC (as stored) and the JPG (upright): 4032x3024 -> 3024x4032, 5712x4284 -> 4284x5712 (same pixel count). Each JPG was opened and looked at: the ticket reads left to right, the title on top.

## 2. Metadata check

`meta.swift` prints every property ImageIO finds in each JPG (`CGImageSourceCopyPropertiesAtIndex`), and the raw bytes were searched for GPS, Apple and iPhone text. Result: no GPS, no make or model, no software, no dates, no orientation note. What is left: resolution (72 dpi), Exif version and pixel-size fields, and the colour profile (Display P3 for the four phone photos, sRGB for dalat.jpg). `dalat.jpg` is the original file, which also has the JFIF header and a comment saying which image library made it ("gd-jpeg"); nothing personal.

## 3. Start the emulator

```
cd app && fvm flutter emulators --launch Pixel_10
adb devices -l        # wait for emulator-5554, and for sys.boot_completed = 1
```

## 4. Run ML Kit on the five pictures

```
app/tool/read_photos.sh emulator-5554 > docs/evidence/16/run.log 2>&1
```

The script (`app/tool/read_photos.sh`) builds the runner (`fvm flutter build apk --debug -t tool/read_photos.dart`), installs it on the named emulator, copies `docs/photos/*.jpg` to the emulator with adb, starts it, waits for it to finish, saves the app's log lines (`run-app.log`) and pulls one JSON file per picture out of the emulator. The runner is `app/tool/read_photos.dart`. Nothing in `app/lib/` or `app/integration_test/` is part of it.

`run.log` is the script's own output; `run-app.log` is the runner's log lines from the emulator, including the device it ran on.

## 5. Build size and the normal app

```
cd app
fvm flutter build apk --release        # with ML Kit: 78.2 MB; before (on main): 46.7 MB
fvm flutter analyze
fvm flutter test
```

The release APK of the normal app was installed on `Pixel_10` and opened: the home screen shows as before.

## 6. Fix round 1: the INTERNET permission

ML Kit's libraries (Google's `transport-backend-cct`) added `android.permission.INTERNET` to the release app. `AndroidManifest.xml` now removes it with `tools:node="remove"`. Permission listings of the built APKs, from `aapt2` in Android build-tools 36.0.0:

```
cd app
fvm flutter build apk --release && fvm flutter build apk --debug
~/Library/Android/sdk/build-tools/36.0.0/aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk > ../docs/evidence/16/permissions-release.txt
~/Library/Android/sdk/build-tools/36.0.0/aapt2 dump permissions build/app/outputs/flutter-apk/app-debug.apk   > ../docs/evidence/16/permissions-debug.txt
```

Release lists no INTERNET; debug still does (`permissions-release.txt`, `permissions-debug.txt`).

**ML Kit with no INTERNET permission** (`no-internet/`). A release build can't use `run-as`, and the debug build gets INTERNET from `app/android/app/src/debug/AndroidManifest.xml`. So for this one run only, I deleted the `<uses-permission ... INTERNET/>` line from that debug manifest, then:

```
app/tool/read_photos.sh emulator-5554 "$PWD/docs/evidence/16/no-internet"
aapt2 dump permissions app/build/app/outputs/flutter-apk/app-debug.apk > docs/evidence/16/no-internet/permissions-runner-debug.txt
git checkout -- app/android/app/src/debug/AndroidManifest.xml     # restored, not committed
```

`no-internet/permissions-runner-debug.txt` lists no INTERNET. (A first attempt of this run failed only because the output folder was given as a relative path; it was repeated.) The run is in `no-internet/` (JSON, `run.log`, `run-app.log`). `run-app.log` also shows the Dart debug service failing to open its local socket ("Operation not permitted"), which is what a build without INTERNET does. The five JSON files were compared with the originals by script: the text, the blocks with all boxes, corner points, angles and confidences, and the picture sizes are identical on all five.

**Release app opens:** the normal release APK was built and installed on `Pixel_10` and opened to the home screen: `release-home.png`.

## 7. Checks by `/work`

- `checks-analyze.txt` and `checks-widget-tests.txt` ran on the Mac.
- `checks-home-screen.txt`, `checks-portrait-lock.txt`, `checks-camera-refused.txt`, `checks-camera-refused-once.txt` and `checks-photo-screen.txt` ran on `Pixel_10` (`emulator-5554`). They are older tickets' tests. They ran because this ticket changed the app's Android setup.
- `failed-run-1/` holds the first try of the last four. All failed, because a "Dò Vé Số isn't responding" pop-up stayed on the emulator and covered the app. The emulator had been up for 4 hours, and the same pop-up had appeared on it on 3 November, before ML Kit was added. After a reboot, all four passed with no new pop-up.
- #8's camera tests (`camera_driver.dart`) were not run. They need the Pixel 7 and someone holding it. `checks-photo-screen.txt` covers the camera path on the emulator.
- By hand, on the release build, on `Pixel_10`: home, "Quét vé", "While using the app", the camera screen (`release-camera.png`), the shutter, the photo screen (`release-photo.png`), back to home.
