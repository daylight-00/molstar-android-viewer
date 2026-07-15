# Architecture

The project intentionally stops at host integration.

```text
Android Activity / SAF / share intents / lifecycle
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
