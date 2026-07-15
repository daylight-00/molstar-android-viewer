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

There is no persistent Android app bar. When startup fails, a native recovery dialog provides **Reload** and **Diagnostics**. During normal operation, file loading and viewer reset operations use Mol*'s own UI.

A structure is considered loaded only after the JavaScript bridge emits `command-completed` for `open-structure`. Selecting a file in the Android picker proves only that the host imported the file into private storage.

## Viewer controls overlap system bars

The application targets SDK 36, where edge-to-edge layout is enforced on modern Android versions. The host applies status-bar, navigation-bar, and display-cutout insets as WebView padding and consumes them before they reach the Mol* document.

## Mol* file button does nothing

Mol* uses a web file input for local structures. `MainActivity` implements `WebChromeClient.onShowFileChooser` and returns Android Storage Access Framework URIs to the WebView. This path is separate from Android `VIEW` and `SEND` intents.
