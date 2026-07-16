# Mol* Android Viewer

A thin Android host for the official Mol* Viewer bundle.

## Design

The project deliberately trusts upstream Mol* and separates responsibilities into three layers:

```text
1. official, unmodified Mol* viewer runtime
2. complete Android platform integration through a stable adapter
3. minimal mobile adaptation and an empty optional custom UI root
```

Mol* owns molecular formats, decompression, multi-file workflows, rendering, analysis, state, and the normal UI. Android owns lifecycle, native file access, system UI, theme signals, and recovery. The project does not fork Mol*, modify its generated JavaScript/CSS, or implement molecular rendering natively.

## Runtime layout

```text
APK
└── Activity
    ├── safe-area FrameLayout
    └── Android System WebView
        ├── vendor/molstar/       official Layer 1
        ├── app-bridge.js         Layer 2 adapter
        ├── theme-controller.js   Layer 2 theme connection
        ├── customization.js      Layer 3 policy
        ├── #app                  upstream Mol* UI
        └── #custom-ui-root       empty by default
```

### Native files

Mol*'s own Open File control is connected to Android through `WebChromeClient.onShowFileChooser`.

Files received through Android `VIEW`, `SEND`, or `SEND_MULTIPLE` are transported without Android-side format interpretation:

```text
content:// URI
→ temporary private bytes + original file name/MIME type
→ browser File object
→ viewer.loadFiles(files)
→ Mol* registry and loaders
```

This preserves upstream support for structures, volumes, compressed files, sessions, archives, and multi-file topology/trajectory workflows without duplicating an extension table in Kotlin.

### Theme and mobile adaptation

Android system light/dark mode selects the official `molstar.css` or `theme/dark.css` stylesheet without recreating molecular state. The separate customization layer currently applies exactly one active policy: hide the non-live log panel. Mol* retains its upstream expansion control and other Viewer defaults. Normal startup has no custom loading overlay; the host diagnostic surface appears only after a terminal startup failure. No upstream DOM or stylesheet is patched.

## Canonical build host

Android builds run on the Linux workstation.

```text
checkout: $HOME/projects/molstar-android-viewer-bootstrap
SDK:      $HOME/opt/Android
```

JavaScript tooling is pinned to the current canonical LTS line:

```text
Node.js: 24.x
npm:     11 or newer
```

The tracked `.nvmrc` is authoritative. Activate it before verification or upstream synchronization:

```bash
nvm install
nvm use
```

Build and verify:

```bash
bash scripts/linux-bootstrap-and-publish.sh
```

Build and fast-forward push to the canonical private GitHub repository by default:

```bash
PUBLISH=1 VISIBILITY=private bash scripts/linux-bootstrap-and-publish.sh
```

## Upstream upgrade

```bash
bash scripts/sync-molstar-assets.sh <molstar-version>
bash scripts/verify.sh
```

The vendor runtime is replaced as a unit. Compatibility is intentionally concentrated in `app-bridge.js` so routine Mol* releases do not require changes to Android platform code.


## Pre-Actions release pipeline

The repository contains the complete build/update/release logic that future GitHub Actions workflows will call. Stable and candidate are separate product flavors, release signing and versioning are environment-driven, Mol* automation is restricted to the upstream vendor directory, and every APK is staged with a machine-readable manifest and SHA-256 checksums.

```bash
# Exercise the entire future CI path with an ephemeral signing key.
bash scripts/ci/simulate-actions.sh

# Build a local candidate debug APK.
bash scripts/ci/build-channel.sh candidate debug
```

Actual workflow YAML, repository secrets, tags, and GitHub Release publication are intentionally deferred. See `docs/automation-readiness.md` and `docs/signing-and-release.md`.

## Android runtime smoke test

With exactly one authorized adb device attached:

```bash
bash scripts/device/verify-debug-apk.sh
```

The smoke gate installs the APK, waits for Mol* readiness, sends a local PDB through an Android content URI, waits for the `open-files` command to complete, rejects viewer errors, and preserves bounded device evidence.

## Collaboration

- Git is the canonical source and history authority.
- The Linux workstation is the canonical Android build host.
- Google Drive carries bounded runner and result archives.
- The Android device is runtime evidence only.
- Assistant changes are delivered as one self-contained Bash runner.
- Verified commits are fast-forward pushed to `origin/main`; divergence stops before push.

See `docs/architecture.md`, `docs/upstream-molstar.md`, and `docs/COLLABORATION_PROTOCOL.md`.
