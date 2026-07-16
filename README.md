# Mol* Android Viewer

An independently maintained Android host for the official Mol* Viewer runtime.

The application packages the upstream prebuilt Viewer without modifying Mol* JavaScript, CSS, molecular formats, rendering, state management, or normal Viewer UI. The Android layer adds device-file integration, lifecycle handling, system insets, theme signals, and bounded startup recovery.

> This repository is not currently presented as an official Mol* release. Public naming and branding will follow guidance from the Mol* maintainers.

## Why an Android application?

The Mol* web application already provides a capable browser-based viewer. This project adds Android-native workflows around the same Viewer:

- open supported files directly from a file manager;
- receive `VIEW`, `SEND`, and `SEND_MULTIPLE` intents;
- use Mol*'s own file picker through Android's Storage Access Framework;
- install stable and candidate builds side by side;
- follow system light/dark mode and avoid system-bar overlap;
- keep the Viewer runtime available as an APK instead of depending on a browser tab.

Files are transported to browser `File` objects with their original names and MIME types, then delegated to `viewer.loadFiles()`. Android does not maintain a separate molecular-format registry or parser.

## Architecture

```text
Layer 3  one explicit mobile policy: hide the non-live log panel
Layer 2  Android lifecycle, files, theme, recovery, and stable bridge
Layer 1  official prebuilt Mol* Viewer runtime, vendored unmodified
```

Mol* owns molecular parsing, decompression, representations, selections, rendering, analysis, state, and the normal user interface. See [the architecture document](docs/development/architecture.md) for the complete boundary.

## Documentation

### Using the application

- [User guide](docs/user/README.md)
- [Troubleshooting](docs/user/troubleshooting.md)

### Developing and maintaining the project

- [Contributing](CONTRIBUTING.md)
- [Developer documentation](docs/development/README.md)
- [Upstream Mol* synchronization](docs/development/upstream-molstar.md)
- [Automation and releases](docs/development/automation.md)

Owner-specific operational procedures are maintained separately from this public repository.

## Quick build

Prerequisites:

- Node.js 24.x and npm 11 or newer;
- JDK 17;
- Android SDK platform 36 and build-tools 36.0.0;
- Bash and standard Unix command-line tools.

```bash
nvm install
nvm use
export ANDROID_SDK_ROOT=/path/to/Android/Sdk
bash scripts/verify.sh
bash scripts/ci/build-channel.sh candidate debug
```

The tracked Gradle wrapper is authoritative. CI uses the same repository-owned scripts as local development.

## Releases

GitHub Actions maintains three bounded paths:

- ordinary CI builds a candidate-debug artifact;
- scheduled upstream checks prepare a signed, parallel-installable candidate pull request;
- stable publication is manual and requires the exact commit approved on a real Android device.

Stable release artifacts are published through GitHub Releases after signing and device approval. See [release documentation](docs/development/releasing.md).

## Upstream and license

Mol* is distributed under the MIT License. Its upstream license and provenance are included under `app/src/main/assets/viewer/vendor/molstar/`.

This Android host is also MIT-licensed. See [LICENSE](LICENSE).
