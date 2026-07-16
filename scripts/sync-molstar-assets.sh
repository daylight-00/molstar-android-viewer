#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-5.10.1}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/app/src/main/assets/viewer/vendor/molstar"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v npm >/dev/null || { echo "npm is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }

cd "$TMP"
npm pack "molstar@$VERSION" --silent >/dev/null
TARBALL="$(find . -maxdepth 1 -name 'molstar-*.tgz' -print -quit)"
mkdir package-root
tar -xzf "$TARBALL" -C package-root
SRC="$TMP/package-root/package"

rm -rf "$DEST"
mkdir -p "$DEST/images" "$DEST/theme"
cp "$SRC/build/viewer/molstar.js" "$DEST/"
cp "$SRC/build/viewer/molstar.css" "$DEST/"
cp "$SRC/build/viewer/theme/dark.css" "$DEST/theme/"
cp "$SRC/build/viewer/favicon.ico" "$DEST/"
cp -a "$SRC/build/viewer/images/." "$DEST/images/"
cp "$SRC/LICENSE" "$DEST/LICENSE"
printf '%s\n' "$VERSION" > "$DEST/VERSION"
(
  cd "$DEST"
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

echo "Synced Mol* $VERSION into $DEST"
