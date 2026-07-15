#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GRADLE_VERSION="${GRADLE_VERSION:-9.4.1}"
REPO_NAME="${REPO_NAME:-molstar-android-viewer}"
VISIBILITY="${VISIBILITY:-private}"
PUBLISH="${PUBLISH:-0}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/molstar-android-viewer"
GRADLE_HOME="$CACHE_DIR/gradle-$GRADLE_VERSION"
ZIP="$CACHE_DIR/gradle-$GRADLE_VERSION-bin.zip"

mkdir -p "$CACHE_DIR"
git config user.name "daylight-00"
git config user.email "hwjang00@snu.ac.kr"

for cmd in curl unzip java git; do
  command -v "$cmd" >/dev/null || {
    echo "Missing $cmd. In Termux: pkg install curl unzip openjdk-17 git" >&2
    exit 1
  }
done

if [[ ! -x "$GRADLE_HOME/bin/gradle" ]]; then
  [[ -s "$ZIP" ]] || curl -fL --retry 3 \
    "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip" \
    -o "$ZIP"
  rm -rf "$GRADLE_HOME"
  unzip -q "$ZIP" -d "$CACHE_DIR"
fi

if [[ ! -f gradle/wrapper/gradle-wrapper.jar ]]; then
  "$GRADLE_HOME/bin/gradle" wrapper --gradle-version "$GRADLE_VERSION" --distribution-type bin
  git add gradlew gradlew.bat gradle/wrapper
  if ! git diff --cached --quiet; then
    git commit -s -m "build: add Gradle wrapper"
  fi
fi

./scripts/verify.sh

if [[ "$PUBLISH" == "1" ]]; then
  command -v gh >/dev/null || { echo "gh is required for publishing" >&2; exit 1; }
  if ! git remote get-url origin >/dev/null 2>&1; then
    case "$VISIBILITY" in
      public) visibility_flag=--public ;;
      private) visibility_flag=--private ;;
      internal) visibility_flag=--internal ;;
      *) echo "VISIBILITY must be public, private, or internal" >&2; exit 1 ;;
    esac
    gh repo create "$REPO_NAME" "$visibility_flag" --source=. --remote=origin --push
  else
    git push -u origin HEAD
  fi
fi

cat <<STATUS
===== final status =====
VERIFY_RC=0
REPO_HEAD=$(git rev-parse HEAD)
REPO_TREE=$(git rev-parse HEAD^{tree})
REPO_BRANCH=$(git branch --show-current)
PUBLISH=$PUBLISH
STATUS
