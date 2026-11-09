#!/bin/bash
# Ticket #16: run ML Kit on the five ticket pictures on the Pixel_10 emulator.
# Usage (from the repo root): app/tool/read_photos.sh <emulator serial, e.g. emulator-5554>
# Optional second argument: the folder to save the output in (default docs/evidence/16).
# The serial is required so the Pixel 7 phone is never touched.
set -euo pipefail
SERIAL="${1:?give the emulator serial, e.g. emulator-5554}"
PKG=com.nampham.lotteryscan
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${2:-$ROOT/docs/evidence/16}"
mkdir -p "$OUT"

echo "device: $SERIAL"
adb -s "$SERIAL" shell getprop ro.product.model
adb -s "$SERIAL" shell getprop ro.boot.qemu.avd_name
adb -s "$SERIAL" shell getprop ro.build.version.release

cd "$ROOT/app"
fvm flutter build apk --debug -t tool/read_photos.dart
adb -s "$SERIAL" install -r build/app/outputs/flutter-apk/app-debug.apk

adb -s "$SERIAL" shell rm -rf /data/local/tmp/mlkit_photos
adb -s "$SERIAL" shell mkdir -p /data/local/tmp/mlkit_photos
adb -s "$SERIAL" push "$ROOT"/docs/photos/*.jpg /data/local/tmp/mlkit_photos/
adb -s "$SERIAL" shell "run-as $PKG sh -c 'rm -rf files/photos files/mlkit_out; mkdir -p files/photos; cp /data/local/tmp/mlkit_photos/*.jpg files/photos/'"
adb -s "$SERIAL" shell rm -rf /data/local/tmp/mlkit_photos

adb -s "$SERIAL" logcat -c
adb -s "$SERIAL" shell am force-stop $PKG
adb -s "$SERIAL" shell am start -n $PKG/.MainActivity

for i in $(seq 1 120); do
  if adb -s "$SERIAL" shell "run-as $PKG ls files/mlkit_out/DONE" >/dev/null 2>&1; then break; fi
  sleep 5
done
adb -s "$SERIAL" logcat -d -s flutter:I > "$OUT/run-app.log"

for f in $(adb -s "$SERIAL" shell "run-as $PKG ls files/mlkit_out" | tr -d '\r'); do
  [ "$f" = DONE ] && continue
  adb -s "$SERIAL" exec-out "run-as $PKG cat files/mlkit_out/$f" > "$OUT/$f"
  echo "pulled $f"
done
