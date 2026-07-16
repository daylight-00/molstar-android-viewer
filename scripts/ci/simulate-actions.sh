#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
SIM_OUTPUT_DIR="${SIM_OUTPUT_DIR:-$ROOT/artifacts/ci-simulation}"
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

for cmd in keytool git; do command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }; done
# shellcheck source=scripts/lib/version-env.sh
source "$ROOT/scripts/lib/version-env.sh"
load_project_versions "$ROOT"
[[ -z "$(git status --porcelain)" ]] || { echo "CI simulation requires a clean worktree" >&2; exit 1; }

KEYSTORE="$TMP/ephemeral-ci.jks"
PASSWORD="ephemeral-ci-password"
keytool -genkeypair -noprompt \
  -keystore "$KEYSTORE" -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -alias ephemeral-ci -dname "CN=Molstar Android Ephemeral CI" \
  -keyalg RSA -keysize 3072 -validity 2 >/dev/null 2>&1
export MOLSTAR_ANDROID_KEYSTORE_FILE="$KEYSTORE"
export MOLSTAR_ANDROID_KEYSTORE_PASSWORD="$PASSWORD"
export MOLSTAR_ANDROID_KEY_ALIAS="ephemeral-ci"
export MOLSTAR_ANDROID_KEY_PASSWORD="$PASSWORD"
export MOLSTAR_ANDROID_VERSION_CODE="${MOLSTAR_ANDROID_VERSION_CODE:-$((900000000 + HOST_VERSION_CODE))}"
export MOLSTAR_ANDROID_VERSION_NAME="${MOLSTAR_ANDROID_VERSION_NAME:-$HOST_VERSION_NAME-ci.$(git rev-parse --short=12 HEAD)}"

rm -rf "$SIM_OUTPUT_DIR"
mkdir -p "$SIM_OUTPUT_DIR"
VERIFY_BUILD=always VERIFY_VARIANT=CandidateRelease bash scripts/verify.sh
ARTIFACT_OUTPUT_DIR="$SIM_OUTPUT_DIR/candidate" SKIP_VERIFY=1 \
  bash scripts/ci/build-channel.sh candidate release
RELEASE_OUTPUT_DIR="$SIM_OUTPUT_DIR/release" RELEASE_REQUIRE_MAIN=0 \
  bash scripts/release/prepare-release.sh
PUBLISH_DRY_RUN=1 bash scripts/release/publish-github-release.sh \
  "$SIM_OUTPUT_DIR/release/release-manifest.json"

CURRENT_VERSION="$(tr -d '[:space:]' < app/src/main/assets/viewer/vendor/molstar/VERSION)"
node scripts/automation/check-molstar-update.mjs --target "$CURRENT_VERSION" \
  --output "$SIM_OUTPUT_DIR/no-update-check.json" >/dev/null

SCOPE_CLONE="$TMP/scope-clone"
git clone --quiet --shared "$ROOT" "$SCOPE_CLONE"
(
  cd "$SCOPE_CLONE"
  node --input-type=module -e '
    import fs from "node:fs";
    const path = "app/src/main/assets/viewer/vendor/molstar/UPSTREAM.json";
    const value = JSON.parse(fs.readFileSync(path, "utf8"));
    value.ciScopeFixture = true;
    fs.writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
  '
  SCOPE_REPORT="$SIM_OUTPUT_DIR/scope-allowed.txt" bash scripts/automation/verify-update-scope.sh HEAD
  git reset --hard -q HEAD
  printf '\nCI scope rejection fixture.\n' >> README.md
  if bash scripts/automation/verify-update-scope.sh HEAD >"$SIM_OUTPUT_DIR/scope-rejected.stdout" 2>"$SIM_OUTPUT_DIR/scope-rejected.stderr"; then
    echo "update scope gate accepted an integration-layer change" >&2
    exit 1
  fi
)

cat <<STATUS
===== final status =====
CI_SIMULATION_RC=0
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
CANDIDATE_MANIFEST=$SIM_OUTPUT_DIR/candidate/artifact-manifest.json
RELEASE_MANIFEST=$SIM_OUTPUT_DIR/release/release-manifest.json
PUBLISH_PLAN=$SIM_OUTPUT_DIR/release/publish-plan.json
SCOPE_GATE=passed
STATUS
