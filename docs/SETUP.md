# Development setup

How to get a machine ready to work on this project.

**Supported:** macOS and Linux. Windows is not supported for now.

**Flutter version:** pinned to **3.47.9** in [`.fvmrc`](../.fvmrc), managed by [FVM](https://fvm.app). Always run Flutter through FVM (`fvm flutter ...`) so everyone uses the same version.

## 1. What you need first

- **Git**
- **Android Studio**: https://developer.android.com/studio. It includes the Android SDK and the emulator.
- **macOS only, for the iPhone version:** Xcode (App Store) and CocoaPods.

## 2. Get the project and run the setup script

```bash
git clone https://github.com/nampham2101/lotteryScanV2.git
cd lotteryScanV2
./setup.sh
```

The script:

1. Checks you're on macOS or Linux.
2. Checks Git, FVM and Flutter 3.47.9. It **asks before installing** anything that's missing.
3. Downloads the project's packages (once the app exists).
4. Runs `flutter doctor` and lists the manual steps left.

Running it again is safe. Anything already installed is skipped.

## 3. Manual steps the script can't do

- **Android command-line tools:** Android Studio → Settings → Android SDK → SDK Tools tab → tick "Android SDK Command-line Tools" → Apply.
- **An emulator:** Android Studio → Device Manager → create a virtual device.
- **Android licenses:** run `fvm flutter doctor --android-licenses`, read them, and type `y`.
- **macOS, iPhone version:** install Xcode from the App Store, then `brew install cocoapods`.

When `fvm flutter doctor` shows no red marks for Android, you're ready.

## 4. Run the app

Not available yet: there's no app code so far.
