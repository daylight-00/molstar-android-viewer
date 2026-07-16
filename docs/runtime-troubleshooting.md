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

A native file batch is considered handed to Mol* only after the JavaScript bridge emits `command-completed` for `open-files`. Selecting a file in Android proves only that the platform transport obtained the URI. Parsing, decompression, format recognition, and multi-file pairing are performed by Mol* through `viewer.loadFiles()`.

## Viewer controls overlap system bars

The application targets SDK 36, where edge-to-edge layout is enforced on modern Android versions. The host applies status-bar, navigation-bar, and display-cutout insets to an outer `FrameLayout`. The WebView is laid out inside that padded safe area so Mol*'s CSS viewport never begins underneath a system bar.

Applying padding directly to `WebView` is insufficient on some Chromium/WebView combinations because absolutely positioned Mol* regions can still use the full WebView viewport.

## Number at the upper-left does not update

Mol*'s optional log panel prefixes each log entry with the time at which that entry was emitted. It is not a clock and therefore does not tick. The separate minimal adaptation layer disables the log panel with the official `layoutShowLog: false` Viewer option; normal diagnostic events remain available through Android logs and the startup recovery dialog.

## Mol* file button does nothing

Mol* uses a web file input for local structures. `MainActivity` implements `WebChromeClient.onShowFileChooser` and returns Android Storage Access Framework URIs to the WebView. This path is separate from Android `VIEW` and `SEND` intents.


## Theme does not follow Android

The viewer uses the official default and dark Mol* stylesheets. `theme-controller.js` reads `MolAndroid.getSystemTheme()` during page startup, and `MainActivity.onConfigurationChanged` forwards later `uiMode` changes to `window.MolTheme` without clearing the loaded molecular state.

## Android share/open rejects a file

The host path accepts Mol* built-in trajectory extensions and gzip-wrapped variants. The inner extension of a `.gz` file must still be recognizable, for example `model.pdb.gz` or `model.bcif.gz`. Multi-file topology/coordinate combinations should be opened from Mol*'s own file control.
