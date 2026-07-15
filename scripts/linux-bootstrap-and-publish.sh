#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO_NAME="${REPO_NAME:-molstar-android-viewer}"
VISIBILITY="${VISIBILITY:-private}"
PUBLISH="${PUBLISH:-0}"
RUN_VERIFY="${RUN_VERIFY:-1}"
ANDROID_SDK_CANDIDATE="${ANDROID_SDK_CANDIDATE:-$HOME/opt/Android}"
export ANDROID_SDK_CANDIDATE

# The collaboration contract uses the same identity for author and committer.
git config --global user.name "daylight-00"
git config --global user.email "hwjang00@snu.ac.kr"
git config user.name "daylight-00"
git config user.email "hwjang00@snu.ac.kr"

for cmd in git java node sha256sum; do
  command -v "$cmd" >/dev/null || {
    echo "Missing required command: $cmd" >&2
    exit 1
  }
done

[[ -x ./gradlew ]] || {
  echo "The tracked Gradle wrapper is missing or not executable." >&2
  exit 1
}

# shellcheck source=scripts/lib/android-env.sh
source "$ROOT/scripts/lib/android-env.sh"
resolve_android_sdk "$ROOT"

if [[ "$RUN_VERIFY" == "1" ]]; then
  VERIFY_BUILD=always "$ROOT/scripts/verify.sh"
fi

if [[ "$PUBLISH" == "1" ]]; then
  command -v gh >/dev/null || { echo "gh is required for publishing" >&2; exit 1; }
  case "$VISIBILITY" in
    public) visibility_flag=--public ;;
    private) visibility_flag=--private ;;
    internal) visibility_flag=--internal ;;
    *) echo "VISIBILITY must be public, private, or internal" >&2; exit 1 ;;
  esac

  if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo create "$REPO_NAME" "$visibility_flag" --source=. --remote=origin --push
  else
    git push -u origin HEAD
  fi
fi

APK="$(find app/build/outputs/apk/debug -maxdepth 1 -type f -name '*.apk' -print -quit 2>/dev/null || true)"
APK_SHA256=""
if [[ -n "$APK" ]]; then
  APK_SHA256="$(sha256sum "$APK" | awk '{print $1}')"
fi

cat <<STATUS
===== final status =====
VERIFY_RC=0
REPO_HEAD=$(git rev-parse HEAD)
REPO_TREE=$(git rev-parse HEAD^{tree})
REPO_BRANCH=$(git branch --show-current)
ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT
APK=${APK:-none}
APK_SHA256=${APK_SHA256:-none}
PUBLISH=$PUBLISH
STATUS
