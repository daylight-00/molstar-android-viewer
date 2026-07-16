# Naming, branding, and upstream guidance

## Current state

```text
UPSTREAM_NAMING_STATUS=pending
PROJECT_TITLE=Mol* Viewer for Android
STABLE_APPLICATION_LABEL=Mol* Viewer
CANDIDATE_APPLICATION_LABEL=Mol* Viewer Candidate
REPOSITORY=https://github.com/daylight-00/molstar-viewer-android
```

The names above remain the current project and application names, but they are not represented as approved or official Mol* branding. This project is independently maintained. A stable public APK will not be published until Mol* maintainer guidance on the names, relationship wording, attribution, and logo boundary is recorded here.

The bundled upstream runtime comes from the official `molstar` npm package. The complete prebuilt `build/viewer` runtime is vendored and distributed as a unit without patches to Mol* JavaScript, CSS, DOM structure, molecular formats, rendering, state management, or normal Viewer UI. The Android host supplies file intents, the Android file picker, lifecycle and renderer recovery, system insets, system-theme signals, and a stable bridge to public Viewer APIs. The only active Viewer option is `layoutShowLog: false`.

## Questions for the Mol* maintainers

Before the first stable release, the project owner will ask:

1. May the Android application use the display name **Mol* Viewer**?
2. May the project use the title **Mol* Viewer for Android**?
3. What wording should describe the relationship between this independently maintained Android host and the upstream Mol* project?
4. May the Mol* logo be used for the application icon, or should the Android project use an independent icon?
5. Is any attribution or citation wording preferred beyond the bundled MIT license and the Mol* Viewer publication?

The response, a permanent link to the upstream discussion, and the resulting decision must be added to this document. `UPSTREAM_NAMING_STATUS` in `project.properties` may be changed to `approved` only in that reviewed commit.

## Draft upstream discussion

**Title:** Permission and naming guidance for an Android host of the unmodified Mol* Viewer

````markdown
Hello Mol* maintainers,

I have built an Android host for the official Mol* Viewer and would like to ask for guidance and permission regarding the project and application names.

Current names:

- Android application: **Mol* Viewer**
- Project: **Mol* Viewer for Android**

Repository:
https://github.com/daylight-00/molstar-viewer-android

The project is intentionally a thin platform host rather than a fork or a separate molecular viewer.

The upstream runtime is obtained from the official `molstar` npm package. The complete prebuilt `build/viewer` runtime is vendored and distributed as a unit without modifications to Mol* JavaScript, CSS, DOM structure, molecular formats, rendering, state management, or normal Viewer UI.

The Android-specific layer provides:

- an Android WebView host;
- Android file-picker integration;
- support for opening device files through VIEW, SEND, and SEND_MULTIPLE intents;
- transport of file bytes, original filenames, and MIME types to `Viewer.loadFiles`;
- Android light/dark theme and system-inset integration;
- lifecycle, renderer-recovery, and startup diagnostics.

The only active product-level Viewer customization is the public Viewer option:

```js
layoutShowLog: false
```

No generated Mol* source or stylesheet is patched.

The motivation is to make the existing Mol* Viewer more convenient for local Android workflows. For example, a molecular file can be opened directly from the Android file manager instead of first navigating to the web application in a browser.

Before publicly distributing a stable APK, I would appreciate your guidance on:

1. May the application use the display name **Mol* Viewer**?
2. May the project use the name **Mol* Viewer for Android**?
3. What wording should be used to make the relationship with the upstream project clear?
4. May the Mol* logo be used for the application icon, or should the Android project use an independent icon?
5. Is there any attribution or citation wording you would prefer beyond the bundled MIT license and the Mol* Viewer publication?

I would be happy to follow any branding or attribution requirements you recommend. The project will clearly identify its maintainer and will not describe itself as an official Mol* release unless you explicitly approve such wording.

Thank you.
````

## Decision matrix

| Upstream guidance | Project response |
|---|---|
| both current names accepted | retain them with the requested relationship statement |
| names accepted with qualifications | retain the names and reproduce the required disclaimer or attribution |
| only **Mol* Viewer for Android** accepted | use that title for both project and installed app if practical |
| current names not accepted | adopt an independent product name and retain clear **Powered by Mol*** attribution |
| logo use not explicitly accepted | use an independent Android application icon |

## Stable-release gate

A stable GitHub Release requires all of the following:

1. upstream naming and branding guidance is recorded here;
2. `UPSTREAM_NAMING_STATUS=approved` is committed in `project.properties`;
3. the permanent signing identity has been verified;
4. the exact release commit has been installed and approved on a real Android device.
