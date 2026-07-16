# User guide

Mol* Android Viewer packages the official Mol* Viewer runtime in an Android application and connects it to Android's file and sharing workflows.

## Installation status

A public stable APK has not been released yet. Stable packages will appear on the repository's GitHub Releases page only after naming guidance, permanent-signing verification, and approval of the exact release commit on a real Android device.

GitHub Actions artifacts are development builds. They may be useful for testing, but they are not long-lived stable packages and should not be redistributed as official releases.

## Opening files

A local file can be opened in three ways:

1. choose the application from an Android file manager's **Open with** action;
2. share one or more files to the application;
3. use Mol*'s own **Open File** control inside the Viewer.

The Android host preserves the original file name and MIME type, creates browser `File` objects, and delegates loading to Mol*. Format recognition, decompression, and multi-file pairing remain Mol* responsibilities.

For topology/trajectory combinations or other multi-file workflows, Mol*'s internal file control is usually the clearest path.

## Stable and candidate applications

Stable and candidate releases use different Android application IDs, so they can be installed at the same time. Candidate builds are intended for testing an upstream update before it becomes stable.

Debug and CI-simulation APKs are development artifacts. They may use temporary signing identities and should not be treated as long-lived updateable releases.

## Appearance

The app follows Android's light/dark setting by selecting the official Mol* default or dark stylesheet. Mol* retains its normal Viewer controls. The only active product option hides Mol*'s non-live log panel.

Normal startup has no custom loading overlay. A diagnostic surface appears only after a terminal startup failure.

## Network behavior

Opening a local file uses an app-private transport path. Mol* features that request online structures or external resources can still make network requests when invoked.

## Play Protect

An APK installed outside Google Play can trigger a Play Protect scan or an unknown-app prompt. A request to scan a previously unseen sideloaded APK is different from an explicit harmful-app verdict. Do not install a package that Android identifies as harmful, blocked, or removed.

See [troubleshooting](troubleshooting.md) for common runtime issues.
