#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
TARGET_VERSION="${1:-latest}"
UPDATE_OUTPUT_DIR="${UPDATE_OUTPUT_DIR:-$ROOT/artifacts/molstar-update}"
BUILD_CANDIDATE="${BUILD_CANDIDATE:-1}"
UPDATE_BUILD_TYPE="${UPDATE_BUILD_TYPE:-debug}"

# shellcheck source=scripts/lib/node-env.sh
source "$ROOT/scripts/lib/node-env.sh"
require_node_lts "$ROOT"
[[ -z "$(git status --porcelain)" ]] || { echo "Mol* update preparation requires a clean worktree" >&2; exit 1; }
BASE_HEAD="$(git rev-parse HEAD)"
BASE_TREE="$(git rev-parse HEAD^{tree})"
CURRENT_VERSION="$(tr -d '[:space:]' < app/src/main/assets/viewer/vendor/molstar/VERSION)"

CHECK_ARGS=()
if [[ "$TARGET_VERSION" != "latest" ]]; then CHECK_ARGS+=(--target "$TARGET_VERSION"); fi
rm -rf "$UPDATE_OUTPUT_DIR"
mkdir -p "$UPDATE_OUTPUT_DIR"
node scripts/automation/check-molstar-update.mjs "${CHECK_ARGS[@]}" --output "$UPDATE_OUTPUT_DIR/update-check.json" >/dev/null
TARGET_VERSION="$(node --input-type=module -e 'import fs from "node:fs"; process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).targetVersion)' "$UPDATE_OUTPUT_DIR/update-check.json")"

if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]]; then
  cat <<STATUS
===== final status =====
UPDATE_RC=0
UPDATE_AVAILABLE=0
CURRENT_VERSION=$CURRENT_VERSION
TARGET_VERSION=$TARGET_VERSION
STATUS
  exit 0
fi

bash scripts/sync-molstar-assets.sh "$TARGET_VERSION"
SCOPE_REPORT="$UPDATE_OUTPUT_DIR/changed-files.txt" bash scripts/automation/verify-update-scope.sh "$BASE_HEAD"
VERIFY_BUILD=never bash scripts/verify.sh

TMP_INDEX="$(mktemp)"
rm -f "$TMP_INDEX"
trap 'rm -f "$TMP_INDEX"' EXIT
GIT_INDEX_FILE="$TMP_INDEX" git read-tree HEAD
GIT_INDEX_FILE="$TMP_INDEX" git add -A
RESULT_TREE="$(GIT_INDEX_FILE="$TMP_INDEX" git write-tree)"
DIFF_SHA256="$(git diff --binary "$BASE_HEAD" -- | sha256sum | awk '{print $1}')"
ARTIFACT_MANIFEST=""
if [[ "$BUILD_CANDIDATE" == "1" ]]; then
  ARTIFACT_OUTPUT_DIR="$UPDATE_OUTPUT_DIR/candidate-artifact" \
    SKIP_VERIFY=1 bash scripts/ci/build-channel.sh candidate "$UPDATE_BUILD_TYPE"
  ARTIFACT_MANIFEST="$UPDATE_OUTPUT_DIR/candidate-artifact/artifact-manifest.json"
fi

node --input-type=module - \
  "$UPDATE_OUTPUT_DIR/update-report.json" "$BASE_HEAD" "$BASE_TREE" "$RESULT_TREE" \
  "$CURRENT_VERSION" "$TARGET_VERSION" "$DIFF_SHA256" "$UPDATE_OUTPUT_DIR/changed-files.txt" \
  "$ARTIFACT_MANIFEST" <<'NODE'
import fs from 'node:fs';
const [output, baseHead, baseTree, resultTree, currentVersion, targetVersion, diffSha256, changedPath, artifactPath] = process.argv.slice(2);
const changedFiles = fs.readFileSync(changedPath, 'utf8').trim().split(/\n/).filter(Boolean);
const report = {
  schemaVersion: 1,
  createdAt: new Date().toISOString(),
  baseHead,
  baseTree,
  resultTree,
  currentVersion,
  targetVersion,
  diffSha256,
  changedFiles,
  artifactManifest: artifactPath || null,
};
fs.writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
NODE
sha256sum "$UPDATE_OUTPUT_DIR/update-report.json" > "$UPDATE_OUTPUT_DIR/update-report.json.sha256"

cat <<STATUS
===== final status =====
UPDATE_RC=0
UPDATE_AVAILABLE=1
BASE_HEAD=$BASE_HEAD
BASE_TREE=$BASE_TREE
RESULT_TREE=$RESULT_TREE
CURRENT_VERSION=$CURRENT_VERSION
TARGET_VERSION=$TARGET_VERSION
DIFF_SHA256=$DIFF_SHA256
UPDATE_REPORT=$UPDATE_OUTPUT_DIR/update-report.json
ARTIFACT_MANIFEST=${ARTIFACT_MANIFEST:-none}
STATUS
