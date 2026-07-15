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

## Build

The Git bundle bootstrap intentionally leaves Gradle wrapper generation to the target Termux environment:

```bash
bash scripts/termux-bootstrap-and-publish.sh
```

To create a private GitHub repository and push it in the same run:

```bash
PUBLISH=1 VISIBILITY=private bash scripts/termux-bootstrap-and-publish.sh
```

## Verify

```bash
bash scripts/verify.sh
```

See `docs/architecture.md` and `docs/local-handoff.md`.
