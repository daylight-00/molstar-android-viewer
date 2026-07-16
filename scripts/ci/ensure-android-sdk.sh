#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-36}"
ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-36.0.0}"

# shellcheck source=scripts/lib/android-env.sh
source "$ROOT/scripts/lib/android-env.sh"
resolve_android_sdk "$ROOT"

find_sdkmanager() {
  local candidate
  for candidate in \
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" \
    "$ANDROID_SDK_ROOT/cmdline-tools/bin/sdkmanager" \
    "$ANDROID_SDK_ROOT/tools/bin/sdkmanager"; do
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  done
  find "$ANDROID_SDK_ROOT/cmdline-tools" -type f -name sdkmanager -perm -u+x -print 2>/dev/null | sort -V | tail -n 1
}

SDKMANAGER="$(find_sdkmanager)"
[[ -n "$SDKMANAGER" && -x "$SDKMANAGER" ]] || {
  echo "sdkmanager was not found under $ANDROID_SDK_ROOT" >&2
  exit 1
}

PLATFORM_JAR="$ANDROID_SDK_ROOT/platforms/$ANDROID_PLATFORM/android.jar"
APKSIGNER="$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS/apksigner"
if [[ ! -s "$PLATFORM_JAR" || ! -x "$APKSIGNER" ]]; then
  yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
  "$SDKMANAGER" --install "platforms;$ANDROID_PLATFORM" "build-tools;$ANDROID_BUILD_TOOLS"
fi

[[ -s "$PLATFORM_JAR" ]] || { echo "Android platform was not installed: $ANDROID_PLATFORM" >&2; exit 1; }
[[ -x "$APKSIGNER" ]] || { echo "Android build tools were not installed: $ANDROID_BUILD_TOOLS" >&2; exit 1; }
printf 'Android SDK ready: %s, build-tools %s\n' "$ANDROID_PLATFORM" "$ANDROID_BUILD_TOOLS"
