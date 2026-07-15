#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive}"
DRIVE_ROOT="${DRIVE_ROOT:-HW-T/molstar-android-viewer/exchange}"
RESULT_FILE="${1:-${RESULT_FILE:-}}"

[[ -n "$RESULT_FILE" && -f "$RESULT_FILE" ]] || {
  echo "usage: $0 /path/to/result.tar.zst" >&2
  exit 2
}
command -v rclone >/dev/null || { echo "rclone is required" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum is required" >&2; exit 1; }

RESULT_FILE="$(cd "$(dirname "$RESULT_FILE")" && pwd -P)/$(basename "$RESULT_FILE")"
SHA_FILE="${RESULT_FILE}.sha256"
sha256sum "$RESULT_FILE" > "$SHA_FILE"
DEST="${RCLONE_REMOTE}:${DRIVE_ROOT}/user-to-agent"

rclone copyto "$RESULT_FILE" "$DEST/$(basename "$RESULT_FILE")" --checksum --progress
rclone copyto "$SHA_FILE" "$DEST/$(basename "$SHA_FILE")" --checksum --progress

cat <<STATUS
===== final status =====
RCLONE_RC=0
RESULT_FILE=$RESULT_FILE
RESULT_SHA256=$(awk '{print $1}' "$SHA_FILE")
DESTINATION=$DEST
STATUS
