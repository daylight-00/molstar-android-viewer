# Architecture

The project is an Android host for upstream Mol*, not an independent molecular viewer implementation.

## Three layers

```text
Layer 3  Minimal adaptation / optional custom UI
                         |
Layer 2  Android platform integration and stable bridge
                         |
Layer 1  Official, unmodified Mol* viewer runtime
```

### Layer 1: upstream Mol*

`app/src/main/assets/viewer/vendor/molstar/` contains the official prebuilt viewer runtime from the `molstar` npm package. It is not edited by hand. JavaScript, stylesheets, themes, images, and other runtime assets are replaced by `scripts/sync-molstar-assets.sh` when the upstream version changes.

Layer 1 owns:

- molecular and volume parsing
- compressed/archive file handling
- topology/coordinates pairing
- representations, selections, camera, and state
- sessions and snapshots
- the normal user interface

The Android project does not fork Mol*, patch `molstar.js`, patch upstream CSS, or depend on Mol* DOM class names.

### Layer 2: Android integration

```text
Android Activity / lifecycle / system UI / native files
                         |
                  ViewerContract.kt
                         |
                    app-bridge.js
                         |
                 public Mol* Viewer API
```

Layer 2 connects platform capabilities without reimplementing Mol* behavior:

- WebView lifecycle and renderer recovery
- system-bar and display-cutout insets
- Android file picker
- `VIEW`, `SEND`, and `SEND_MULTIPLE` intents
- transport of `content://` bytes, original names, and MIME types
- system light/dark mode selection of official Mol* stylesheets
- external URL routing
- startup diagnostics

Native files are copied into a temporary private transport directory and exposed through `WebViewAssetLoader`. `app-bridge.js` fetches them, creates browser `File` objects with their original names, and calls `viewer.loadFiles(files)`. Android does not recognize extensions, decide binary/text mode, decompress gzip, or choose Mol* format keys.

The stable product-level command boundary currently includes:

- `open-files`
- `open-structure`
- `open-pdb`
- `open-alphafold`
- `clear`

Mol* internals remain isolated in `app-bridge.js`. Future native controls add stable commands rather than calling `viewer.plugin.*` from Kotlin.

### Layer 3: minimal adaptation

`customization.js` is intentionally separate from both upstream Mol* and the Android bridge. It currently contains only explicit mobile policy:

- hide the non-live log panel
- hide the redundant browser expansion control
- initialize an empty `#custom-ui-root`

The custom root is absent from layout while empty and does not intercept pointer input. Future custom UI mounts there without inserting elements into Mol* DOM or modifying upstream stylesheets.

## Upgrade boundary

A normal Mol* upgrade should be:

```bash
bash scripts/sync-molstar-assets.sh <version>
bash scripts/verify.sh
```

Expected code impact:

1. replace Layer 1 as a unit;
2. verify the small set of public Viewer capabilities used by Layer 2;
3. change only `app-bridge.js` if an upstream public API changed;
4. leave Android platform code and Layer 3 policy unchanged.

## Non-goals

- Mol* source fork
- native molecular renderer or data model
- native representation/selection UI
- Android copy of Mol*'s format registry
- PyMOL-compatible command console
- CSS or DOM patches tied to a specific Mol* release
