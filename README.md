# Mol* Android Viewer

A thin Android host for the official Mol* Viewer bundle.

## Scope

The application keeps Mol*'s complete built-in UI. Android handles only platform integration:

- APK lifecycle and WebView hosting
- local structure files through Mol*'s own file controls and Android share/open intents
- `VIEW` and `SEND` intents
- PDB ID loading
- system-bar safe-area handling through an outer host container, without a persistent native app bar
- native reload and diagnostics controls only when WebView or Mol* startup fails
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

Files selected inside Mol* are returned through `WebChromeClient.onShowFileChooser`. Files received from Android `VIEW` or `SEND` intents are copied from `content://` URIs into private app storage and exposed through `WebViewAssetLoader` under the HTTPS-like `appassets.androidplatform.net` origin.

The Android action bar is intentionally absent. Mol* owns the normal viewer UI; Android shows native recovery controls only when startup fails.

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

Build and fast-forward push to the canonical GitHub `origin` (`daylight-00/molstar-android-viewer`) by default:

```bash
PUBLISH=1 VISIBILITY=private bash scripts/linux-bootstrap-and-publish.sh
```

## Verify

```bash
bash scripts/verify.sh
```

## Android runtime smoke test

The adb gate is optional and deferred until the Linux workstation is configured for device access. With exactly one authorized adb device attached:

```bash
bash scripts/device/verify-debug-apk.sh
```

The smoke test installs the debug APK, waits for the Mol* `ready` event, sends a local PDB through an Android `ACTION_VIEW` content URI, waits for the `open-structure` completion event, rejects viewer error events, and preserves logcat, screenshot, device, WebView-provider, package, APK, and fixture evidence below `~/Downloads/hw-t-device-results/`.

`VERIFY_BUILD=auto` builds when both the Gradle wrapper and SDK are available. Use `VERIFY_BUILD=always` to require a build or `VERIFY_BUILD=never` for static verification only.

## Collaboration

- Google Drive carries bounded assistant/user `.tar.zst` packages and complete result archives.
- The Linux workstation uses `rclone`; the assistant uses the Google Drive connector against the same exchange folders.
- The Android device is runtime evidence only and is accessed from Linux with `adb`; the repository never lives on the device.
- Termux and rsync are not part of this workflow.
- Git remains the canonical source and history authority.
- Assistant changes are delivered as one self-contained Bash runner; only its initial `rclone copyto` is manual.
- Result uploads are staged below `~/Downloads` before rclone access.
- Verified runner commits are fast-forward pushed to `origin/main` by default; divergence stops before push.

See:

- `docs/architecture.md`
- `docs/linux-handoff.md`
- `docs/COLLABORATION_PROTOCOL.md`
- `docs/runtime-troubleshooting.md`
- `docs/GITHUB_COLLABORATION_WORKFLOW.md`
