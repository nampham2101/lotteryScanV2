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
