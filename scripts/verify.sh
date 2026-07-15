#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  app/src/main/assets/viewer/index.html
  app/src/main/assets/viewer/app-bridge.js
  app/src/main/assets/viewer/vendor/molstar/molstar.js
  app/src/main/assets/viewer/vendor/molstar/molstar.css
  app/src/main/assets/viewer/vendor/molstar/LICENSE
  app/src/main/assets/viewer/vendor/molstar/VERSION
  app/src/main/assets/viewer/vendor/molstar/SHA256SUMS
)
for path in "${required[@]}"; do
  [[ -s "$path" ]] || { echo "missing or empty: $path" >&2; exit 1; }
done

node --check app/src/main/assets/viewer/app-bridge.js
(
  cd app/src/main/assets/viewer/vendor/molstar
  sha256sum -c SHA256SUMS
)

grep -q 'window.MolApp' app/src/main/assets/viewer/app-bridge.js
grep -q 'WebViewAssetLoader' app/src/main/java/io/github/daylight00/molstarandroid/MainActivity.kt

if [[ -x ./gradlew && -n "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ]]; then
  ./gradlew --no-daemon :app:assembleDebug
else
  echo "Static verification passed; Android build deferred (wrapper or SDK unavailable)."
fi
