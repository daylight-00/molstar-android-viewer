#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
RELEASE_OUTPUT_DIR="${RELEASE_OUTPUT_DIR:-$ROOT/artifacts/release}"
RELEASE_REQUIRE_MAIN="${RELEASE_REQUIRE_MAIN:-1}"

# shellcheck source=scripts/lib/node-env.sh
source "$ROOT/scripts/lib/node-env.sh"
require_node_lts "$ROOT"
# shellcheck source=scripts/lib/signing-env.sh
source "$ROOT/scripts/lib/signing-env.sh"
require_signing_env

[[ "${MOLSTAR_ANDROID_VERSION_CODE:-}" =~ ^[1-9][0-9]*$ ]] || {
  echo "MOLSTAR_ANDROID_VERSION_CODE must be explicitly set for a stable release" >&2
  exit 1
}
[[ -z "$(git status --porcelain)" ]] || { echo "stable release preparation requires a clean worktree" >&2; exit 1; }
if [[ "$RELEASE_REQUIRE_MAIN" == "1" ]]; then
  [[ "$(git branch --show-current)" == "main" ]] || { echo "stable release preparation requires branch main" >&2; exit 1; }
fi

ARTIFACT_OUTPUT_DIR="$RELEASE_OUTPUT_DIR/stable-artifact" \
  bash scripts/ci/build-channel.sh stable release
ARTIFACT_MANIFEST="$RELEASE_OUTPUT_DIR/stable-artifact/artifact-manifest.json"

node --input-type=module - "$ARTIFACT_MANIFEST" "$RELEASE_OUTPUT_DIR" <<'NODE'
import fs from 'node:fs';
import path from 'node:path';
const [artifactManifestPath, outputDir] = process.argv.slice(2);
const artifact = JSON.parse(fs.readFileSync(artifactManifestPath, 'utf8'));
if (artifact.channel !== 'stable' || artifact.buildType !== 'release' || !artifact.signed) {
  throw new Error('Stable release artifact must be a signed stable release build');
}
const tag = `v${artifact.versionName}`;
const release = {
  schemaVersion: 1,
  preparedAt: new Date().toISOString(),
  tag,
  title: `Mol* Viewer for Android ${artifact.versionName}`,
  targetCommit: artifact.sourceHead,
  artifactManifest: path.relative(outputDir, artifactManifestPath),
  apkFile: path.relative(outputDir, path.join(path.dirname(artifactManifestPath), artifact.apkFile)),
  apkSha256: artifact.apkSha256,
  applicationId: artifact.applicationId,
  versionCode: artifact.versionCode,
  versionName: artifact.versionName,
  molstarVersion: artifact.molstarVersion,
  certificateSha256: artifact.certificateSha256,
};
fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(path.join(outputDir, 'release-manifest.json'), `${JSON.stringify(release, null, 2)}\n`);
const notes = `# ${release.title}\n\n` +
  `- Mol* runtime: ${release.molstarVersion}\n` +
  `- Android version code: ${release.versionCode}\n` +
  `- Commit: ${release.targetCommit}\n` +
  `- APK SHA-256: ${release.apkSha256}\n` +
  `- Signing certificate SHA-256: ${release.certificateSha256}\n\n` +
  `This package contains the official unmodified Mol* Viewer runtime, the Android integration layer, and the minimal customization layer.\n`;
fs.writeFileSync(path.join(outputDir, 'release-notes.md'), notes);
NODE
(
  cd "$RELEASE_OUTPUT_DIR"
  sha256sum release-manifest.json release-notes.md stable-artifact/* > RELEASE_SHA256SUMS
)

cat <<STATUS
===== final status =====
RELEASE_PREP_RC=0
RELEASE_READY=1
RELEASE_MANIFEST=$RELEASE_OUTPUT_DIR/release-manifest.json
RELEASE_NOTES=$RELEASE_OUTPUT_DIR/release-notes.md
ARTIFACT_MANIFEST=$ARTIFACT_MANIFEST
STATUS
