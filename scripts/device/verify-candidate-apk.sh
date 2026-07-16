#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export APP_ID="${APP_ID:-io.github.daylight00.molstarandroid.candidate}"
export ACTIVITY="${ACTIVITY:-$APP_ID/.MainActivity}"
exec "$ROOT/scripts/device/verify-apk.sh" "${1:-${APK_PATH:-}}"
