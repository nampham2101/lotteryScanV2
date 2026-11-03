#!/usr/bin/env bash
# Gets a Mac or Linux machine ready to develop this project.
# Asks before installing anything. Safe to run again: installed pieces are skipped.
# Full guide: docs/SETUP.md

set -euo pipefail
cd "$(dirname "$0")"

FLUTTER_VERSION="$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' .fvmrc)"

step() { printf '\n==> %s\n' "$1"; }
ok()   { printf '    ✓ %s\n' "$1"; }
note() { printf '    - %s\n' "$1"; }

# Returns 0 if the developer answers y.
ask() {
  local reply=""
  printf '    %s (y/n) ' "$1"
  read -r reply || true
  [[ "$reply" =~ ^[Yy]$ ]]
}

stop() {
  printf '\n    %s\n    Run ./setup.sh again when ready.\n' "$1"
  exit 1
}

step "Checking the system"
case "$(uname -s)" in
  Darwin) OS="mac" ;;
  Linux)  OS="linux" ;;
  *) echo "This script supports macOS and Linux only. See docs/SETUP.md." >&2; exit 1 ;;
esac
ok "$OS"

step "Checking Git"
if command -v git >/dev/null 2>&1; then
  ok "$(git --version)"
else
  stop "Git is missing. Install it first (macOS: xcode-select --install, Linux: your package manager)."
fi

step "Checking FVM (Flutter version manager)"
if command -v fvm >/dev/null 2>&1; then
  ok "FVM $(fvm --version)"
elif ask "FVM is not installed. Install it now?"; then
  if [[ "$OS" == "mac" ]]; then
    command -v brew >/dev/null 2>&1 || stop "Homebrew is needed to install FVM on macOS: https://brew.sh"
    brew tap btwld/fvm
    brew install btwld/fvm/fvm
  else
    curl -fsSL https://fvm.app/install.sh | bash
    export PATH="${FVM_INSTALL_DIR:-$HOME/fvm}/bin:$PATH"
    note "Add FVM to your PATH for future shells (the installer above printed the line to add)."
  fi
  ok "FVM $(fvm --version)"
else
  stop "FVM is required."
fi

step "Checking Flutter $FLUTTER_VERSION"
if fvm list 2>/dev/null | grep -qF "$FLUTTER_VERSION"; then
  ok "Flutter $FLUTTER_VERSION is installed"
elif ask "Flutter $FLUTTER_VERSION is not installed (about 1-2 GB download). Install it now?"; then
  fvm install
  ok "Flutter $FLUTTER_VERSION is installed"
else
  stop "Flutter $FLUTTER_VERSION is required."
fi

step "Checking project packages"
if [[ ! -f pubspec.yaml ]]; then
  note "No Flutter app yet (no pubspec.yaml). Skipping."
elif ask "Download the project's packages now?"; then
  fvm flutter pub get
  ok "Packages downloaded"
else
  note "Skipped. Run: fvm flutter pub get"
fi

step "Running flutter doctor"
fvm flutter doctor || true

step "Manual steps left (the script can't do these)"
note "Android Studio: https://developer.android.com/studio"
note "In Android Studio: Settings > Android SDK > SDK Tools > tick 'Android SDK Command-line Tools' > Apply"
note "Create an emulator: Android Studio > Device Manager"
note "Accept the Android licenses (read them, type y): fvm flutter doctor --android-licenses"
if [[ "$OS" == "mac" ]]; then
  note "For the iPhone version: install Xcode from the App Store, then CocoaPods (brew install cocoapods)"
fi
printf '\nDone. Anything marked [!] or [✗] in flutter doctor above still needs attention.\n'
