#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-5.10.1}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/app/src/main/assets/viewer/vendor/molstar"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v npm >/dev/null || { echo "npm is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }
command -v node >/dev/null || { echo "node is required" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum is required" >&2; exit 1; }

cd "$TMP"
TARBALL="$(npm pack "molstar@$VERSION" --silent | tail -n 1)"
[[ -n "$TARBALL" && -s "$TARBALL" ]] || { echo "npm pack did not produce a tarball" >&2; exit 1; }
TARBALL_SHA256="$(sha256sum "$TARBALL" | awk '{print $1}')"
mkdir package-root
tar -xzf "$TARBALL" -C package-root
SRC="$TMP/package-root/package"
[[ -d "$SRC/build/viewer" ]] || { echo "Mol* package has no build/viewer directory" >&2; exit 1; }
[[ -s "$SRC/package.json" ]] || { echo "Mol* package has no package.json" >&2; exit 1; }
PACKAGE_VERSION="$(node -e "const p=require(process.argv[1]); process.stdout.write(String(p.version))" "$SRC/package.json")"
[[ "$PACKAGE_VERSION" == "$VERSION" ]] || {
  echo "requested Mol* $VERSION but npm package reports $PACKAGE_VERSION" >&2
  exit 1
}

rm -rf "$DEST"
mkdir -p "$DEST"
# Layer 1 is copied from the official prebuilt viewer as a unit. Source maps are
# development metadata and are excluded from the APK; runtime files stay byte-for-byte.
cp -a "$SRC/build/viewer/." "$DEST/"
find "$DEST" -type f -name '*.map' -delete
cp "$SRC/LICENSE" "$DEST/LICENSE"
printf '%s\n' "$PACKAGE_VERSION" > "$DEST/VERSION"
node - "$DEST/UPSTREAM.json" "$PACKAGE_VERSION" "$TARBALL" "$TARBALL_SHA256" <<'NODE'
const fs = require('fs');
const output = {
    package: 'molstar',
    version: process.argv[3],
    filename: process.argv[4],
    tarballSha256: process.argv[5],
    source: 'npm',
    copiedPath: 'build/viewer',
    excluded: ['**/*.map'],
};
fs.writeFileSync(process.argv[2], `${JSON.stringify(output, null, 2)}\n`);
NODE
(
  cd "$DEST"
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

echo "Synced unmodified Mol* viewer runtime $PACKAGE_VERSION into $DEST"
