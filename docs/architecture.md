# Architecture

The project intentionally stops at host integration.

```text
Android Activity / file chooser / share intents / lifecycle
                    |
             ViewerContract.kt
                    |
              app-bridge.js
                    |
          Mol* Viewer / PluginContext
```

## Stable boundary

Android code sends product-level JSON commands only:

- `open-structure`
- `open-pdb`
- `open-alphafold`
- `clear`

Mol* internal APIs are isolated in `app-bridge.js`. Future native UI controls should add commands to this contract rather than calling `viewer.plugin.*` from Kotlin.

## Current non-goals

- Native representation or selection UI
- PyMOL-compatible command console
- Mol* source fork
- Native molecular renderer
- Android-side molecular data model

## Native UI policy

The normal application surface is the Mol* viewer itself. The Android action bar is removed. System-bar and display-cutout insets are applied to an outer native `FrameLayout`, while the WebView fills the container's safe content area.

The mobile viewer keeps Mol* controls and sequence UI but disables the log panel. Its displayed timestamps describe individual log events; they are not a live clock.

Android UI appears only for host-level recovery:

- reload after WebView or Mol* startup failure
- startup diagnostics

Mol* file inputs are delegated to Android through `WebChromeClient.onShowFileChooser`. Android `VIEW` and `SEND` intents remain supported independently of the visible viewer UI.
