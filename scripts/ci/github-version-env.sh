#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHANNEL="${1:?channel is required}"
RUN_NUMBER="${2:?GitHub workflow run number is required}"
TARGET_MOLSTAR_VERSION="${3:-}"

# shellcheck source=scripts/lib/version-env.sh
source "$ROOT/scripts/lib/version-env.sh"
load_project_versions "$ROOT"

[[ "$RUN_NUMBER" =~ ^[1-9][0-9]*$ ]] || {
  echo "GitHub workflow run number must be a positive integer" >&2
  exit 1
}
if [[ -n "$TARGET_MOLSTAR_VERSION" ]]; then
  [[ "$TARGET_MOLSTAR_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || {
    echo "target Mol* version is invalid: $TARGET_MOLSTAR_VERSION" >&2
    exit 1
  }
else
  TARGET_MOLSTAR_VERSION="$MOLSTAR_VERSION"
fi

case "$CHANNEL" in
  stable)
    BASE_CODE=1000000000
    VERSION_NAME="$HOST_VERSION_NAME-molstar.$TARGET_MOLSTAR_VERSION"
    ;;
  candidate)
    BASE_CODE=1100000000
    VERSION_NAME="$HOST_VERSION_NAME-molstar.$TARGET_MOLSTAR_VERSION-ci.$RUN_NUMBER"
    ;;
  *)
    echo "channel must be stable or candidate" >&2
    exit 1
    ;;
esac

VERSION_CODE=$((BASE_CODE + RUN_NUMBER))
(( VERSION_CODE <= 2100000000 )) || {
  echo "derived Android versionCode exceeds the platform limit: $VERSION_CODE" >&2
  exit 1
}

printf 'MOLSTAR_ANDROID_VERSION_CODE=%s\n' "$VERSION_CODE"
printf 'MOLSTAR_ANDROID_VERSION_NAME=%s\n' "$VERSION_NAME"
printf 'HOST_VERSION_NAME=%s\n' "$HOST_VERSION_NAME"
printf 'TARGET_MOLSTAR_VERSION=%s\n' "$TARGET_MOLSTAR_VERSION"
