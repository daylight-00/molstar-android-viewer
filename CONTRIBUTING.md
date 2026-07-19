# Contributing

Changes should preserve the central boundary: Mol* remains the molecular product layer, while this repository supplies a thin Android host.

## Setup

Requirements: Node.js 24.x, npm 11 or newer, JDK 17, Android SDK platform 36, build-tools 36.0.0, Git, Bash, and standard Unix tools.

```bash
git clone <repository-url>
cd molstar-viewer-android
nvm install
nvm use
export ANDROID_SDK_ROOT=/path/to/Android/Sdk
bash scripts/verify.sh
```

Build a candidate debug APK with:

```bash
bash scripts/ci/build-channel.sh candidate debug
```

## Project boundary

Read [docs/architecture.md](docs/architecture.md) before changing runtime behavior.

- Do not edit `app/src/main/assets/viewer/vendor/molstar/**` by hand.
- Android code transports files and platform signals; it does not interpret molecular formats.
- Mol* integration goes through public Viewer APIs in `app-bridge.js`.
- Do not patch upstream generated JavaScript, CSS, or DOM structure.
- Keep keystores, credentials, private structures, and confidential diagnostics out of the repository.

Use `bash scripts/sync-molstar-assets.sh <version>` for upstream updates. See [docs/maintenance.md](docs/maintenance.md) for update and release paths.

## Pull requests

Keep changes narrow. State what changed, how it was verified, whether a real-device test was performed, and whether the change affects upstream assets, Android behavior, signing, or releases.
