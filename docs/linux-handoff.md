# Linux workstation handoff

The canonical build checkout is:

```text
$HOME/projects/molstar-android-viewer-bootstrap
```

The default Android SDK location is:

```text
$HOME/opt/Android
```

The canonical JavaScript toolchain is tracked in `.nvmrc` and currently requires Node.js 24.x with npm 11 or newer. Activate it in each fresh shell before running project scripts:

```bash
cd "$HOME/projects/molstar-android-viewer-bootstrap"
nvm install
nvm use
node --version
npm --version
```

The repository deliberately does not maintain Node 12 compatibility shims.

Run:

```bash
cd "$HOME/projects/molstar-android-viewer-bootstrap"
bash scripts/linux-bootstrap-and-publish.sh
```

The runner:

1. configures global and repository-local Git identity as `daylight-00 <hwjang00@snu.ac.kr>`;
2. resolves the Android SDK from environment variables or `$HOME/opt/Android`;
3. writes ignored `local.properties`;
4. verifies the vendored Mol* bundle and JavaScript bridge;
5. builds `app-debug.apk` with the tracked Gradle wrapper;
6. optionally creates or pushes the GitHub repository with `PUBLISH=1`.

Build without publishing:

```bash
PUBLISH=0 bash scripts/linux-bootstrap-and-publish.sh
```

Verified builds are fast-forward pushed to the canonical `origin/main` by default:

```bash
PUBLISH=1 VISIBILITY=private bash scripts/linux-bootstrap-and-publish.sh
```

Set `PUBLISH=0` only for an explicitly local gate. The publish path requires `gh auth status`, creates or resolves `daylight-00/molstar-android-viewer`, migrates a bootstrap bundle remote to `bootstrap-source`, and fetches `origin/main`, rejects divergence, performs a normal push, and reads the remote ref back.

Drive exchange from Linux uses rclone:

```bash
bash scripts/rclone/pull-agent-packages.sh
bash scripts/rclone/push-user-result.sh /path/to/result.tar.zst
```

Install the built APK directly from Linux when needed:

```bash
bash scripts/device/install-debug-apk.sh
```

Run the bounded device smoke test with one authorized adb device:

```bash
bash scripts/device/verify-debug-apk.sh
```

It verifies the Mol* ready event and a native `ACTION_VIEW` local-PDB import, then preserves complete Linux-side evidence below `~/Downloads/hw-t-device-results/`.

There is no Termux checkout or rsync stage. See `COLLABORATION_PROTOCOL.md` for exact boundaries.
