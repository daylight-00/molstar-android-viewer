#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO_NAME="${REPO_NAME:-molstar-android-viewer}"
GITHUB_OWNER="${GITHUB_OWNER:-daylight-00}"
GITHUB_REPO="${GITHUB_REPO:-$GITHUB_OWNER/$REPO_NAME}"
GITHUB_REMOTE_URL="${GITHUB_REMOTE_URL:-https://github.com/$GITHUB_REPO.git}"
VISIBILITY="${VISIBILITY:-private}"
PUBLISH="${PUBLISH:-1}"
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

  gh auth status >/dev/null
  authenticated_login="$(gh api user --jq .login)"
  [[ "$authenticated_login" == "$GITHUB_OWNER" ]] || {
    echo "gh is authenticated as $authenticated_login, expected $GITHUB_OWNER" >&2
    exit 1
  }

  current_branch="$(git branch --show-current)"
  [[ "$current_branch" == "main" ]] || {
    echo "Publishing requires branch main, found: $current_branch" >&2
    exit 1
  }

  if ! gh repo view "$GITHUB_REPO" --json nameWithOwner >/dev/null 2>&1; then
    gh repo create "$GITHUB_REPO" "$visibility_flag" \
      --description "Thin Android host for the official Mol* Viewer bundle"
  fi

  target_url="$GITHUB_REMOTE_URL"
  if git remote get-url origin >/dev/null 2>&1; then
    current_origin="$(git remote get-url origin)"
    if [[ "$current_origin" != "$target_url" ]]; then
      if git remote get-url bootstrap-source >/dev/null 2>&1; then
        [[ "$(git remote get-url bootstrap-source)" == "$current_origin" ]] || {
          echo "bootstrap-source already exists with a different URL" >&2
          exit 1
        }
        git remote remove origin
      else
        git remote rename origin bootstrap-source
      fi
    fi
  fi
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$target_url"
  else
    git remote add origin "$target_url"
  fi

  remote_head="$(git ls-remote origin refs/heads/main | awk 'NR == 1 { print $1 }')"
  if [[ -n "$remote_head" ]]; then
    git fetch --prune origin main
    git merge-base --is-ancestor "$remote_head" HEAD || {
      echo "origin/main is not an ancestor of local HEAD; refusing non-fast-forward push" >&2
      exit 1
    }
  fi

  git push --porcelain -u origin HEAD:refs/heads/main
  pushed_head="$(git ls-remote origin refs/heads/main | awk 'NR == 1 { print $1 }')"
  [[ "$pushed_head" == "$(git rev-parse HEAD)" ]] || {
    echo "remote readback does not match local HEAD" >&2
    exit 1
  }
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
