# Mol* Viewer for Android

[![CI](https://github.com/molstar/molstar-viewer-android/actions/workflows/ci.yml/badge.svg)](https://github.com/molstar/molstar-viewer-android/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Mol* Viewer packaged as an Android application with native device-file integration.

The application uses the upstream prebuilt Mol* Viewer runtime without patching its JavaScript, CSS, molecular formats, rendering, state management, or normal user interface.

## Android integration

- open supported files from Android file managers;
- receive `VIEW`, `SEND`, and `SEND_MULTIPLE` intents;
- use Mol*'s own file picker through Android's Storage Access Framework;
- follow the system light/dark setting and avoid system-bar overlap;
- install candidate builds beside stable releases.

Files are delivered to Mol* as browser `File` objects with their original names and MIME types. Parsing, decompression, representations, selections, rendering, and scientific workflows remain Mol* responsibilities.

## Architecture

```text
Layer 3  minimal mobile policy
   ↓
Layer 2  Android lifecycle, files, theme, recovery, and stable bridge
   ↓
Layer 1  upstream prebuilt Mol* Viewer runtime, vendored unmodified
```

See [Architecture](docs/architecture.md) for the complete boundary.

## Documentation

Use the [Mol* Viewer documentation](https://molstar.org/viewer-docs/) for Viewer controls, selections, representations, measurements, sessions, and other scientific workflows.

This repository documents only the Android-specific behavior:

- [Using the Android app](docs/android.md)
- [Maintenance and releases](docs/maintenance.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

## Build

Requirements: Node.js 24.x, npm 11 or newer, JDK 17, Android SDK platform 36, and build-tools 36.0.0.

```bash
git clone https://github.com/molstar/molstar-viewer-android.git
cd molstar-viewer-android
nvm install
nvm use
export ANDROID_SDK_ROOT=/path/to/Android/Sdk
bash scripts/verify.sh
bash scripts/ci/build-channel.sh candidate debug
```

Stable releases require permanent signing and approval of the exact release commit on a real Android device. GitHub Actions artifacts are development builds.

## License

Mol* and this Android host are distributed under the MIT License. Upstream license and provenance are included under `app/src/main/assets/viewer/vendor/molstar/`.
