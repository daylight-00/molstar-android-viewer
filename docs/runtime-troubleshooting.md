# Runtime troubleshooting

## Viewer area stays blank

A blank area with only the Android host background means the Mol* React UI was not mounted. The bundled Mol* viewer contains generated JavaScript and WebAssembly paths, so the local Content Security Policy must permit `unsafe-eval` and `wasm-unsafe-eval` while still limiting scripts to the bundled app origin.

The load order is intentionally:

```text
boot-diagnostics.js
  -> vendor/molstar/molstar.js
  -> app-bridge.js
```

The first script records synchronous script failures and unhandled promise rejections before the vendor bundle runs. Startup failures remain visible in the WebView and are also sent to Android through `MolAndroid.postEvent`.

The overflow menu provides:

- **Reload viewer** to restart the WebView without reopening the Android activity.
- **Diagnostics** to show readiness, queued commands, current URL, WebView version, and the latest viewer error.

A structure is considered loaded only after the JavaScript bridge emits `command-completed` for `open-structure`. Selecting a file in the Android picker proves only that the host imported the file into private storage.
