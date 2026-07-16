# Contributing

Contributions should preserve the project's central constraint: Mol* remains the molecular product layer, while this repository provides a thin Android host.

## Development setup

The Bash-based tooling is tested on Ubuntu in GitHub Actions. A Linux, macOS, or compatible Unix-like environment is recommended.

Required tools:

- Node.js 24.x, selected by `.nvmrc`;
- npm 11 or newer;
- JDK 17;
- Android SDK platform 36 and build-tools 36.0.0;
- Git, Bash, `sha256sum`, `unzip`, and the tracked Gradle wrapper.

```bash
git clone <repository-url>
cd molstar-viewer-android
nvm install
nvm use
export ANDROID_SDK_ROOT=/path/to/Android/Sdk
bash scripts/verify.sh
```

Build a local candidate-debug artifact:

```bash
bash scripts/ci/build-channel.sh candidate debug
```

The artifact directory includes the APK, output metadata, checksums, signing information, and a machine-readable provenance manifest.

## Architectural rules

Before changing runtime behavior, read [docs/development/architecture.md](docs/development/architecture.md).

Changes must respect these boundaries:

1. `vendor/molstar/**` is replaced as an upstream unit and is not edited by hand.
2. Android code transports files and platform signals but does not interpret molecular formats.
3. Mol* integration uses the public Viewer API through `app-bridge.js`.
4. Upstream CSS and generated JavaScript are not patched.
5. `layoutShowLog: false` is the only active custom Viewer option unless a reviewed product requirement changes that policy.
6. Keystores, passwords, and decoded signing material must never enter the repository or build artifacts.

## Verification

Static and build verification:

```bash
bash scripts/verify.sh
```

Select a specific build variant when necessary:

```bash
VERIFY_BUILD=always VERIFY_VARIANT=CandidateRelease bash scripts/verify.sh
```

Release variants require the complete signing environment described in [docs/development/releasing.md](docs/development/releasing.md).

With an authorized Android device:

```bash
bash scripts/device/verify-debug-apk.sh
```

A successful desktop build does not prove WebView rendering, touch behavior, file intents, or device stability. Report build evidence and device evidence separately.

## Upstream updates

Use the synchronization script rather than modifying vendored files:

```bash
bash scripts/sync-molstar-assets.sh <version>
bash scripts/verify.sh
```

Automated update preparation is restricted to `app/src/main/assets/viewer/vendor/molstar/**`. See [docs/development/upstream-molstar.md](docs/development/upstream-molstar.md).

## Issues and security

Use the structured issue forms for public bug reports and feature requests. Do not open a public issue for a suspected vulnerability; follow [SECURITY.md](SECURITY.md) and use private vulnerability reporting. Never upload confidential molecular structures or diagnostics without first reducing and sanitizing them.

## Pull requests

Keep pull requests narrow and explain:

- the user-visible or maintenance problem;
- the affected architectural layer;
- verification performed;
- whether a real-device check was performed;
- any release or compatibility implications.

Do not combine an upstream Mol* replacement with unrelated Android or UI changes.
