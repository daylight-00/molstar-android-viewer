#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive}"
DRIVE_ROOT="${DRIVE_ROOT:-HW-T/molstar-android-viewer/exchange}"
LOCAL_DIR="${LOCAL_DIR:-$ROOT/build/exchange/agent-to-user}"

command -v rclone >/dev/null || { echo "rclone is required" >&2; exit 1; }
mkdir -p "$LOCAL_DIR"
rclone copy "${RCLONE_REMOTE}:${DRIVE_ROOT}/agent-to-user" "$LOCAL_DIR" \
  --checksum --create-empty-src-dirs --progress

cat <<STATUS
===== final status =====
RCLONE_RC=0
SOURCE=${RCLONE_REMOTE}:${DRIVE_ROOT}/agent-to-user
LOCAL_DIR=$LOCAL_DIR
STATUS
