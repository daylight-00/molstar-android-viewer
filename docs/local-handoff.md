# Termux handoff

Import the Git bundle and complete the build locally:

```bash
git clone /path/to/molstar-android-viewer-bootstrap.bundle molstar-android-viewer
cd molstar-android-viewer
PUBLISH=1 VISIBILITY=private bash scripts/termux-bootstrap-and-publish.sh
```

The runner:

1. configures repository-local Git identity as `daylight-00 <hwjang00@snu.ac.kr>`;
2. downloads Gradle 9.4.1 only when the wrapper is absent;
3. generates and commits the official Gradle wrapper;
4. runs static verification and `assembleDebug` when the Android SDK is available;
5. optionally creates and pushes the GitHub repository using `gh`.

Set `PUBLISH=0` to build without creating a remote repository.
