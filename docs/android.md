# Using the Android app

The Viewer interface and scientific workflows are upstream Mol*. Use the [Mol* Viewer documentation](https://molstar.org/viewer-docs/) and [Mol* cheat sheet](https://molstar.org/viewer-docs/mol_-cheat-sheet/) for navigation, selections, representations, measurements, sessions, and display controls.

This document covers only Android-specific behavior.

## Opening files

Files can enter the app through:

1. **Open with** from an Android file manager;
2. Android **Share** for one or more files;
3. Mol*'s **Open File** control inside the Viewer.

The Android host preserves each file's original name and MIME type, creates browser `File` objects, and delegates loading to Mol*. Format recognition, decompression, topology/trajectory pairing, and visualization remain upstream behavior.

For workflows that require several related files, selecting them together through Mol*'s own file control is usually the clearest path.

## Touch controls

Mol* handles the canvas directly. Touch gestures such as one-finger rotation, two-finger translation, and pinch zoom follow the upstream Viewer documentation.

## Local and network data

Local files are copied into an app-private temporary transport area before they are passed to the Viewer. Mol* features that fetch structures or external resources can still use the network when invoked.

## Android-specific recovery

- A blank Viewer should surface a native recovery dialog. Try **Reload**, then include **Diagnostics** when reporting a persistent failure.
- Mol*'s file button requires an available Android system document picker.
- Preserve meaningful filename extensions, including inner extensions such as `model.pdb.gz`.
- Report controls overlapping system bars with the device model, Android version, orientation, and a screenshot.

Sideloaded APKs can trigger an unknown-app prompt or Play Protect scan. Do not install a package that Android explicitly identifies as harmful, blocked, or removed.
