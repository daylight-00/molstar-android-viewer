#!/usr/bin/env bash

SIGNING_ENV_NAMES=(
  MOLSTAR_ANDROID_KEYSTORE_FILE
  MOLSTAR_ANDROID_KEYSTORE_PASSWORD
  MOLSTAR_ANDROID_KEY_ALIAS
  MOLSTAR_ANDROID_KEY_PASSWORD
)

signing_env_complete() {
  local name
  for name in "${SIGNING_ENV_NAMES[@]}"; do
    [[ -n "${!name:-}" ]] || return 1
  done
  [[ -s "$MOLSTAR_ANDROID_KEYSTORE_FILE" ]]
}

require_signing_env() {
  local missing=() name
  for name in "${SIGNING_ENV_NAMES[@]}"; do
    [[ -n "${!name:-}" ]] || missing+=("$name")
  done
  if ((${#missing[@]})); then
    printf 'Missing Android signing inputs: %s\n' "${missing[*]}" >&2
    return 1
  fi
  [[ -s "$MOLSTAR_ANDROID_KEYSTORE_FILE" ]] || {
    printf 'Android signing keystore not found or empty: %s\n' "$MOLSTAR_ANDROID_KEYSTORE_FILE" >&2
    return 1
  }
}
