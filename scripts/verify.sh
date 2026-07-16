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
  app/src/main/assets/viewer/customization.js
  app/src/main/assets/viewer/boot-diagnostics.js
  app/src/main/assets/viewer/theme-controller.js
  app/src/main/assets/viewer/vendor/molstar/molstar.js
  app/src/main/assets/viewer/vendor/molstar/molstar.css
  app/src/main/assets/viewer/vendor/molstar/theme/dark.css
  app/src/main/assets/viewer/vendor/molstar/LICENSE
  app/src/main/assets/viewer/vendor/molstar/VERSION
  app/src/main/assets/viewer/vendor/molstar/UPSTREAM.json
  app/src/main/assets/viewer/vendor/molstar/SHA256SUMS
  scripts/device/fixtures/minimal-ala.pdb
  scripts/device/verify-debug-apk.sh
  scripts/verify-viewer-shell.mjs
  scripts/verify-native-file-bridge.mjs
)
for path in "${required[@]}"; do
  [[ -s "$path" ]] || { echo "missing or empty: $path" >&2; exit 1; }
done

for cmd in node sha256sum grep diff find sort; do
  command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }
done

node --check app/src/main/assets/viewer/app-bridge.js
node --check app/src/main/assets/viewer/customization.js
node --check app/src/main/assets/viewer/boot-diagnostics.js
node --check app/src/main/assets/viewer/theme-controller.js
node scripts/verify-viewer-shell.mjs
node scripts/verify-native-file-bridge.mjs
bash -n scripts/sync-molstar-assets.sh
bash -n scripts/device/install-debug-apk.sh
bash -n scripts/device/verify-debug-apk.sh
bash -n scripts/linux-bootstrap-and-publish.sh
bash -n scripts/rclone/push-user-result.sh
(
  cd app/src/main/assets/viewer/vendor/molstar
  sha256sum -c SHA256SUMS
  declared="$(mktemp)"
  actual="$(mktemp)"
  trap 'rm -f "$declared" "$actual"' EXIT
  awk '{ sub(/^\*/, "", $2); print $2 }' SHA256SUMS | sort > "$declared"
  find . -type f ! -name SHA256SUMS -print | sort > "$actual"
  diff -u "$declared" "$actual"
)

MAIN=app/src/main/java/io/github/daylight00/molstarandroid/MainActivity.kt
CONTRACT=app/src/main/java/io/github/daylight00/molstarandroid/ViewerContract.kt
MANIFEST=app/src/main/AndroidManifest.xml
BRIDGE=app/src/main/assets/viewer/app-bridge.js
CUSTOM=app/src/main/assets/viewer/customization.js

grep -q 'window.MolApp' "$BRIDGE"
grep -q 'viewer.loadFiles(files)' "$BRIDGE"
grep -q 'case '\''open-files'\''' "$BRIDGE"
grep -q 'WebViewAssetLoader' "$MAIN"
grep -q 'onShowFileChooser' "$MAIN"
grep -q 'WindowInsets.Type.systemBars()' "$MAIN"
grep -q 'WindowInsets.Type.displayCutout()' "$MAIN"
grep -q 'private lateinit var rootView: FrameLayout' "$MAIN"
grep -q 'rootView.addView(webView)' "$MAIN"
grep -q 'getSystemTheme' "$MAIN"
grep -q 'onConfigurationChanged' "$MAIN"
grep -q 'Intent.ACTION_SEND_MULTIPLE' "$MAIN"
grep -q 'ViewerContract.openFiles' "$MAIN"
grep -q 'fun openFiles' "$CONTRACT"
grep -q 'layoutShowLog: false' "$CUSTOM"
grep -q 'android.intent.action.SEND_MULTIPLE' "$MANIFEST"

if grep -Eq 'GZIPInputStream|detectStructureFile|inferFormat|lammps_traj_data|chemical/x-' "$MAIN" "$MANIFEST"; then
  echo 'Android integration must not duplicate Mol* format recognition or decompression' >&2
  exit 1
fi
if grep -q 'layoutShowLog' "$BRIDGE"; then
  echo 'custom Viewer options must stay in customization.js, not app-bridge.js' >&2
  exit 1
fi
if grep -q 'applySystemBarInsets(this)' "$MAIN"; then
  echo 'system insets must be applied to the outer host container, not the WebView' >&2
  exit 1
fi
grep -q 'android:windowNoTitle">true' app/src/main/res/values/styles.xml
if grep -q 'onCreateOptionsMenu' "$MAIN"; then
  echo 'persistent Android options menu must remain absent' >&2
  exit 1
fi

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
