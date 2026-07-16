#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APK_PATH="${APK_PATH:-$(find "$ROOT/app/build/outputs/apk/candidate/debug" -maxdepth 1 -type f -name '*.apk' -print -quit 2>/dev/null || true)}"

# shellcheck source=scripts/lib/android-env.sh
source "$ROOT/scripts/lib/android-env.sh"
resolve_android_sdk "$ROOT"
ADB="${ADB:-$ANDROID_SDK_ROOT/platform-tools/adb}"
[[ -x "$ADB" ]] || { echo "adb not found: $ADB" >&2; exit 1; }
[[ -n "$APK_PATH" && -s "$APK_PATH" ]] || { echo "candidate debug APK not found; build first or set APK_PATH" >&2; exit 1; }
"$ADB" get-state >/dev/null
"$ADB" install -r "$APK_PATH"
cat <<STATUS
===== final status =====
ADB_RC=0
APK=$APK_PATH
APK_SHA256=$(sha256sum "$APK_PATH" | awk '{print $1}')
STATUS
