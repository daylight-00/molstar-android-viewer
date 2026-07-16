#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPOSITORY="${GITHUB_REPOSITORY:-}"
KEYSTORE_PATH="${KEYSTORE_PATH:-$HOME/.local/share/molstar-android-viewer/sideload.jks}"
KEY_ALIAS="${KEY_ALIAS:-molstar-android-sideload}"

for cmd in keytool gh base64; do
  command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }
done
gh auth status >/dev/null
if [[ -z "$REPOSITORY" ]]; then
  REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi
[[ -n "$REPOSITORY" ]] || { echo "could not resolve GitHub repository" >&2; exit 1; }
mkdir -p "$(dirname "$KEYSTORE_PATH")"
chmod 700 "$(dirname "$KEYSTORE_PATH")"

if [[ ! -s "$KEYSTORE_PATH" ]]; then
  echo "Creating the permanent sideload key at: $KEYSTORE_PATH"
  echo "Record the passwords in a password manager and keep an encrypted offline backup."
  keytool -genkeypair \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 3072 -validity 10000
  chmod 600 "$KEYSTORE_PATH"
else
  echo "Reusing existing keystore: $KEYSTORE_PATH"
fi

read -r -s -p 'Keystore password: ' STORE_PASSWORD; printf '\n'
read -r -s -p 'Key password: ' KEY_PASSWORD; printf '\n'
keytool -list -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" >/dev/null

base64 -w 0 "$KEYSTORE_PATH" | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPOSITORY"
printf '%s' "$STORE_PASSWORD" | gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$REPOSITORY"
printf '%s' "$KEY_ALIAS" | gh secret set ANDROID_KEY_ALIAS --repo "$REPOSITORY"
printf '%s' "$KEY_PASSWORD" | gh secret set ANDROID_KEY_PASSWORD --repo "$REPOSITORY"

CERT_SHA256="$(keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" 2>/dev/null | sed -n 's/^[[:space:]]*SHA256: //p' | head -n 1 | tr -d ':[:space:]')"
unset STORE_PASSWORD KEY_PASSWORD

cat <<STATUS
===== final status =====
SIGNING_CONFIG_RC=0
REPOSITORY=$REPOSITORY
KEYSTORE_PATH=$KEYSTORE_PATH
KEY_ALIAS=$KEY_ALIAS
CERTIFICATE_SHA256=${CERT_SHA256:-unknown}
SECRETS=ANDROID_KEYSTORE_BASE64,ANDROID_KEYSTORE_PASSWORD,ANDROID_KEY_ALIAS,ANDROID_KEY_PASSWORD
STATUS
