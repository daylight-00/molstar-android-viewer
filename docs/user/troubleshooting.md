# Troubleshooting

## The Viewer area stays blank

Use the native recovery dialog's **Reload** or **Diagnostics** action. Normal startup is intentionally silent, so an error surface indicates that Mol* failed to mount or did not become ready in time.

When reporting the problem, include the Android version, WebView provider/version, app version, and the diagnostics output.

## Viewer controls overlap system bars

The host applies status-bar, navigation-bar, and display-cutout insets around the WebView. Confirm that the app is current and report the device model, Android version, orientation, and a screenshot if controls still overlap.

## The file button does nothing

Mol*'s file control opens Android's Storage Access Framework picker. Confirm that a system file picker is available and that the selected document provider grants read access.

This path is separate from opening the application through a file manager's **Open with** command.

## Android rejects a shared or opened file

The Android host does not parse formats itself. It passes bytes, the original file name, and MIME type to Mol*. Preserve meaningful extensions, including the inner extension of compressed files such as `model.pdb.gz`.

For multi-file topology/coordinate workflows, select the related files together from Mol*'s own file control.

## Theme changes do not appear

The app selects the official Mol* default or dark stylesheet from Android's current system theme. Restart the Activity once to distinguish a configuration-delivery problem from a stylesheet problem, then report the device and WebView versions.

## A number in the upper-left does not update

Mol*'s optional log panel prefixes entries with their emission time; it is not a clock. This project hides that panel in normal builds using the official `layoutShowLog: false` option.
