#!/usr/bin/env bash

load_project_versions() {
  local root="${1:?repository root is required}"
  local file="$root/version.properties"
  [[ -s "$file" ]] || { echo "version.properties is missing" >&2; return 1; }

  HOST_VERSION_CODE="$(sed -n 's/^HOST_VERSION_CODE=//p' "$file" | tail -n 1)"
  HOST_VERSION_NAME="$(sed -n 's/^HOST_VERSION_NAME=//p' "$file" | tail -n 1)"
  MOLSTAR_VERSION="$(tr -d '[:space:]' < "$root/app/src/main/assets/viewer/vendor/molstar/VERSION")"

  [[ "$HOST_VERSION_CODE" =~ ^[1-9][0-9]*$ ]] || {
    echo "HOST_VERSION_CODE must be a positive integer" >&2
    return 1
  }
  [[ "$HOST_VERSION_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || {
    echo "HOST_VERSION_NAME is invalid: $HOST_VERSION_NAME" >&2
    return 1
  }
  [[ "$MOLSTAR_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || {
    echo "Mol* VERSION is invalid: $MOLSTAR_VERSION" >&2
    return 1
  }

  export HOST_VERSION_CODE HOST_VERSION_NAME MOLSTAR_VERSION
}
