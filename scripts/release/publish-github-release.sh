#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
MANIFEST="${1:-${RELEASE_OUTPUT_DIR:-$ROOT/artifacts/release}/release-manifest.json}"
PUBLISH_DRY_RUN="${PUBLISH_DRY_RUN:-0}"
REPOSITORY="${GITHUB_REPOSITORY:-}"

for cmd in git node sha256sum; do
  command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }
done
if [[ "$PUBLISH_DRY_RUN" != "1" ]]; then
  command -v gh >/dev/null || { echo "missing command: gh" >&2; exit 1; }
fi
if [[ -z "$REPOSITORY" ]] && command -v gh >/dev/null 2>&1; then
  REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
fi
if [[ -z "$REPOSITORY" ]]; then
  origin_url="$(git remote get-url origin 2>/dev/null || true)"
  case "$origin_url" in
    https://github.com/*.git) REPOSITORY="${origin_url#https://github.com/}"; REPOSITORY="${REPOSITORY%.git}" ;;
    git@github.com:*.git) REPOSITORY="${origin_url#git@github.com:}"; REPOSITORY="${REPOSITORY%.git}" ;;
  esac
fi
if [[ -z "$REPOSITORY" && "$PUBLISH_DRY_RUN" == "1" ]]; then
  REPOSITORY="local/repository"
fi
[[ -n "$REPOSITORY" ]] || { echo "could not resolve GitHub repository" >&2; exit 1; }
[[ -s "$MANIFEST" ]] || { echo "release manifest not found: $MANIFEST" >&2; exit 1; }
OUTPUT_DIR="$(cd "$(dirname "$MANIFEST")" && pwd)"

mapfile -t RELEASE_VALUES < <(node --input-type=module - "$MANIFEST" <<'NODE'
import fs from 'node:fs';
import path from 'node:path';
const manifestPath = process.argv[2];
const value = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
for (const key of ['tag', 'title', 'targetCommit', 'apkFile', 'artifactManifest']) {
  if (typeof value[key] !== 'string' || !value[key]) throw new Error(`release manifest field is missing: ${key}`);
}
const root = path.dirname(manifestPath);
for (const item of [value.tag, value.title, value.targetCommit, path.resolve(root, value.apkFile), path.resolve(root, value.artifactManifest)]) {
  process.stdout.write(`${item}\n`);
}
NODE
)
TAG="${RELEASE_VALUES[0]}"
TITLE="${RELEASE_VALUES[1]}"
TARGET_COMMIT="${RELEASE_VALUES[2]}"
APK="${RELEASE_VALUES[3]}"
ARTIFACT_MANIFEST="${RELEASE_VALUES[4]}"
NOTES="$OUTPUT_DIR/release-notes.md"
RELEASE_SUMS="$OUTPUT_DIR/RELEASE_SHA256SUMS"
ARTIFACT_SUMS="$(dirname "$ARTIFACT_MANIFEST")/SHA256SUMS"

for file in "$APK" "$ARTIFACT_MANIFEST" "$NOTES" "$RELEASE_SUMS" "$ARTIFACT_SUMS"; do
  [[ -s "$file" ]] || { echo "release asset is missing: $file" >&2; exit 1; }
done
[[ -z "$(git status --porcelain)" ]] || { echo "release publication requires a clean worktree" >&2; exit 1; }
[[ "$(git rev-parse HEAD)" == "$TARGET_COMMIT" ]] || {
  echo "release target does not match HEAD" >&2
  exit 1
}
(
  cd "$OUTPUT_DIR"
  sha256sum -c RELEASE_SHA256SUMS
)

ASSETS=("$APK" "$ARTIFACT_MANIFEST" "$ARTIFACT_SUMS" "$MANIFEST" "$NOTES" "$RELEASE_SUMS")
if [[ "$PUBLISH_DRY_RUN" == "1" ]]; then
  node --input-type=module - "$OUTPUT_DIR/publish-plan.json" "$REPOSITORY" "$TAG" "$TITLE" "$TARGET_COMMIT" "${ASSETS[@]}" <<'NODE'
import fs from 'node:fs';
const [output, repository, tag, title, targetCommit, ...assets] = process.argv.slice(2);
fs.writeFileSync(output, `${JSON.stringify({ schemaVersion: 1, repository, tag, title, targetCommit, assets }, null, 2)}\n`);
NODE
  echo "GitHub Release publication dry-run passed: $TAG"
  exit 0
fi

[[ -n "${GH_TOKEN:-}" ]] || { echo "GH_TOKEN is required for release publication" >&2; exit 1; }
REMOTE_TAG_COMMIT=""
if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  git fetch --quiet origin "refs/tags/$TAG:refs/tags/$TAG"
  REMOTE_TAG_COMMIT="$(git rev-list -n 1 "$TAG")"
  [[ "$REMOTE_TAG_COMMIT" == "$TARGET_COMMIT" ]] || {
    echo "existing tag $TAG points to $REMOTE_TAG_COMMIT instead of $TARGET_COMMIT" >&2
    exit 1
  }
fi

if gh release view "$TAG" --repo "$REPOSITORY" >/dev/null 2>&1; then
  gh release edit "$TAG" --repo "$REPOSITORY" --title "$TITLE" --notes-file "$NOTES"
  gh release upload "$TAG" "${ASSETS[@]}" --repo "$REPOSITORY" --clobber
else
  CREATE_ARGS=("$TAG" "${ASSETS[@]}" --repo "$REPOSITORY" --title "$TITLE" --notes-file "$NOTES")
  if [[ -n "$REMOTE_TAG_COMMIT" ]]; then
    CREATE_ARGS+=(--verify-tag)
  else
    CREATE_ARGS+=(--target "$TARGET_COMMIT")
  fi
  gh release create "${CREATE_ARGS[@]}"
fi

gh release view "$TAG" --repo "$REPOSITORY" --json tagName,url,targetCommitish > "$OUTPUT_DIR/published-release.json"
echo "GitHub Release published: $TAG"
