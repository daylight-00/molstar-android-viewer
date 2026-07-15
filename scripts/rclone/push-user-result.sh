#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive}"
DRIVE_ROOT="${DRIVE_ROOT:-HW-T/molstar-android-viewer/exchange}"
RESULT_FILE="${1:-${RESULT_FILE:-}}"
RCLONE_STAGE_DIR="${RCLONE_STAGE_DIR:-$HOME/Downloads/hw-t-rclone-staging/molstar-android-viewer}"

[[ -n "$RESULT_FILE" && -f "$RESULT_FILE" ]] || {
  echo "usage: $0 /path/to/result.tar.zst" >&2
  exit 2
}
command -v rclone >/dev/null || { echo "rclone is required" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum is required" >&2; exit 1; }
command -v install >/dev/null || { echo "install is required" >&2; exit 1; }

RESULT_FILE="$(cd "$(dirname "$RESULT_FILE")" && pwd -P)/$(basename "$RESULT_FILE")"
mkdir -p "$RCLONE_STAGE_DIR"
RCLONE_STAGE_DIR="$(cd "$RCLONE_STAGE_DIR" && pwd -P)"
STAGED_FILE="$RCLONE_STAGE_DIR/$(basename "$RESULT_FILE")"

if [[ "$RESULT_FILE" != "$STAGED_FILE" ]]; then
  install -m 0644 "$RESULT_FILE" "$STAGED_FILE"
else
  chmod 0644 "$STAGED_FILE"
fi

SHA_FILE="${STAGED_FILE}.sha256"
(
  cd "$RCLONE_STAGE_DIR"
  sha256sum "$(basename "$STAGED_FILE")" > "$(basename "$SHA_FILE")"
)
chmod 0644 "$SHA_FILE"

DEST="${RCLONE_REMOTE}:${DRIVE_ROOT}/user-to-agent"
rclone copyto "$STAGED_FILE" "$DEST/$(basename "$STAGED_FILE")" --checksum --progress
rclone copyto "$SHA_FILE" "$DEST/$(basename "$SHA_FILE")" --checksum --progress
rclone lsf "$DEST" --include "$(basename "$STAGED_FILE")*"

cat <<STATUS
===== final status =====
RCLONE_RC=0
SOURCE_FILE=$RESULT_FILE
STAGED_FILE=$STAGED_FILE
RESULT_SHA256=$(awk '{print $1}' "$SHA_FILE")
DESTINATION=$DEST
STATUS
