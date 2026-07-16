#!/usr/bin/env bash

# Canonical JavaScript toolchain for Mol* asset synchronization and contract tests.
# Keep this aligned with the tracked .nvmrc when the project deliberately moves LTS.
require_node_lts() {
  local root="${1:-$(pwd)}"
  local minimum_npm_major="${NPM_MIN_MAJOR:-11}"
  local node_version node_major npm_version npm_major tracked_major required_major

  tracked_major="$(tr -d '[:space:]' < "$root/.nvmrc" 2>/dev/null || true)"
  [[ "$tracked_major" =~ ^[0-9]+$ ]] || {
    echo ".nvmrc must contain one Node.js major version, found: ${tracked_major:-missing}" >&2
    return 1
  }
  required_major="${NODE_LTS_MAJOR:-$tracked_major}"

  command -v node >/dev/null || {
    echo "Node.js ${required_major}.x LTS is required; node was not found" >&2
    return 1
  }
  command -v npm >/dev/null || {
    echo "npm ${minimum_npm_major}+ is required; npm was not found" >&2
    return 1
  }

  node_version="$(node --version)" || return $?
  node_major="${node_version#v}"
  node_major="${node_major%%.*}"
  [[ "$node_major" =~ ^[0-9]+$ ]] || {
    echo "Could not parse Node.js version: $node_version" >&2
    return 1
  }

  [[ "$tracked_major" == "$required_major" ]] || {
    echo ".nvmrc must contain canonical Node major $required_major, found: ${tracked_major:-missing}" >&2
    return 1
  }
  [[ "$node_major" == "$required_major" ]] || {
    echo "Node.js ${required_major}.x LTS is required, found $node_version" >&2
    echo "Run: nvm install $required_major && nvm use $required_major" >&2
    return 1
  }

  npm_version="$(npm --version)" || return $?
  npm_major="${npm_version%%.*}"
  [[ "$npm_major" =~ ^[0-9]+$ ]] || {
    echo "Could not parse npm version: $npm_version" >&2
    return 1
  }
  (( npm_major >= minimum_npm_major )) || {
    echo "npm ${minimum_npm_major}+ is required with Node.js ${required_major}.x, found $npm_version" >&2
    return 1
  }

  node -e '
    const required = ["Blob", "File", "fetch"];
    const missing = required.filter(name => typeof globalThis[name] !== "function");
    if (missing.length) {
      console.error(`Node.js runtime is missing required web globals: ${missing.join(", ")}`);
      process.exit(1);
    }
  ' || return $?

  printf 'NODE_VERSION=%s\nNPM_VERSION=%s\n' "$node_version" "$npm_version"
}
