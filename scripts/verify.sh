#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERIFY_BUILD="${VERIFY_BUILD:-auto}"
ANDROID_SDK_CANDIDATE="${ANDROID_SDK_CANDIDATE:-$HOME/opt/Android}"
export ANDROID_SDK_CANDIDATE

required=(
  app/src/main/assets/viewer/index.html
  app/src/main/assets/viewer/app-bridge.js
  app/src/main/assets/viewer/boot-diagnostics.js
  app/src/main/assets/viewer/vendor/molstar/molstar.js
  app/src/main/assets/viewer/vendor/molstar/molstar.css
  app/src/main/assets/viewer/vendor/molstar/LICENSE
  app/src/main/assets/viewer/vendor/molstar/VERSION
  app/src/main/assets/viewer/vendor/molstar/SHA256SUMS
  scripts/device/fixtures/minimal-ala.pdb
  scripts/device/verify-debug-apk.sh
  scripts/verify-viewer-shell.mjs
)
for path in "${required[@]}"; do
  [[ -s "$path" ]] || { echo "missing or empty: $path" >&2; exit 1; }
done

for cmd in node sha256sum grep; do
  command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }
done

node --check app/src/main/assets/viewer/app-bridge.js
node --check app/src/main/assets/viewer/boot-diagnostics.js
node scripts/verify-viewer-shell.mjs
bash -n scripts/device/install-debug-apk.sh
bash -n scripts/device/verify-debug-apk.sh
bash -n scripts/linux-bootstrap-and-publish.sh
bash -n scripts/rclone/push-user-result.sh
(
  cd app/src/main/assets/viewer/vendor/molstar
  sha256sum -c SHA256SUMS
)

grep -q 'window.MolApp' app/src/main/assets/viewer/app-bridge.js
grep -q 'WebViewAssetLoader' app/src/main/java/io/github/daylight00/molstarandroid/MainActivity.kt

do_build=0
case "$VERIFY_BUILD" in
  never)
    do_build=0
    ;;
  auto)
    if [[ -x ./gradlew ]]; then
      # shellcheck source=scripts/lib/android-env.sh
      source "$ROOT/scripts/lib/android-env.sh"
      if resolve_android_sdk "$ROOT"; then
        do_build=1
      fi
    fi
    ;;
  always)
    [[ -x ./gradlew ]] || { echo "Gradle wrapper is unavailable" >&2; exit 1; }
    # shellcheck source=scripts/lib/android-env.sh
    source "$ROOT/scripts/lib/android-env.sh"
    resolve_android_sdk "$ROOT"
    do_build=1
    ;;
  *)
    echo "VERIFY_BUILD must be auto, always, or never" >&2
    exit 1
    ;;
esac

if [[ "$do_build" == "1" ]]; then
  ./gradlew --no-daemon :app:assembleDebug
  APK="$(find app/build/outputs/apk/debug -maxdepth 1 -type f -name '*.apk' -print -quit)"
  [[ -n "$APK" && -s "$APK" ]] || { echo "debug APK was not produced" >&2; exit 1; }
  echo "Android build passed: $APK"
  sha256sum "$APK"
else
  echo "Static verification passed; Android build deferred."
fi
