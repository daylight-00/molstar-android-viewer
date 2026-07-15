# Mol* Android Viewer

A thin Android host for the official Mol* Viewer bundle.

## Scope

The application keeps Mol*'s complete built-in UI. Android handles only platform integration:

- APK lifecycle and WebView hosting
- local structure files through the Storage Access Framework
- `VIEW` and `SEND` intents
- PDB ID loading
- an intentionally small JSON bridge for possible future UI integration

The project does not fork Mol* and does not implement molecular rendering natively.

## Runtime layout

```text
APK
└── Activity
    └── Android System WebView
        ├── app-bridge.js
        └── official Mol* viewer bundle
```

Local files are copied from `content://` URIs into private app storage and exposed to the WebView through `WebViewAssetLoader` under the HTTPS-like `appassets.androidplatform.net` origin.

## Canonical build host

Android builds run on the separate Linux workstation.

```text
checkout: $HOME/projects/molstar-android-viewer-bootstrap
SDK:      $HOME/opt/Android
```

Build and verify:

```bash
bash scripts/linux-bootstrap-and-publish.sh
```

The SDK path can be overridden with `ANDROID_SDK_ROOT`, `ANDROID_HOME`, or `ANDROID_SDK_CANDIDATE`.

Create and push a private GitHub repository only when requested:

```bash
PUBLISH=1 VISIBILITY=private bash scripts/linux-bootstrap-and-publish.sh
```

## Verify

```bash
bash scripts/verify.sh
```

`VERIFY_BUILD=auto` builds when both the Gradle wrapper and SDK are available. Use `VERIFY_BUILD=always` to require a build or `VERIFY_BUILD=never` for static verification only.

## Collaboration

- Google Drive carries bounded assistant/user `.tar.zst` packages and complete result archives.
- The Linux workstation uses `rclone`; the assistant uses the Google Drive connector against the same exchange folders.
- The Android device is optional runtime evidence only and is accessed from Linux with `adb`.
- Termux and rsync are not part of this workflow.
- Git remains the canonical source and history authority.

See:

- `docs/architecture.md`
- `docs/linux-handoff.md`
- `docs/COLLABORATION_PROTOCOL.md`
- `docs/GITHUB_COLLABORATION_WORKFLOW.md`
