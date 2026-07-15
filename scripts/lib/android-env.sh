#!/usr/bin/env bash

# Shared Android SDK discovery for the canonical Linux workstation workflow.
# Source this file and call resolve_android_sdk <repository-root>.

resolve_android_sdk() {
  local repo_root="${1:?repository root is required}"
  local sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${ANDROID_SDK_CANDIDATE:-$HOME/opt/Android}}}"

  if [[ "$sdk_root" == "~/"* ]]; then
    sdk_root="$HOME/${sdk_root#~/}"
  fi

  if [[ ! -d "$sdk_root" ]]; then
    printf 'Android SDK not found: %s\n' "$sdk_root" >&2
    printf 'Set ANDROID_SDK_ROOT or ANDROID_SDK_CANDIDATE.\n' >&2
    return 1
  fi

  sdk_root="$(cd "$sdk_root" && pwd -P)"
  export ANDROID_SDK_ROOT="$sdk_root"
  export ANDROID_HOME="$sdk_root"

  local escaped="$sdk_root"
  escaped="${escaped//\\/\\\\}"
  escaped="${escaped//:/\\:}"
  escaped="${escaped// /\\ }"
  printf 'sdk.dir=%s\n' "$escaped" > "$repo_root/local.properties"
}
