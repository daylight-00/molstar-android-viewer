# Linux workstation handoff

The canonical build checkout is:

```text
$HOME/projects/molstar-android-viewer-bootstrap
```

The default Android SDK location is:

```text
$HOME/opt/Android
```

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

Create and push a private repository only after verification:

```bash
PUBLISH=1 VISIBILITY=private bash scripts/linux-bootstrap-and-publish.sh
```

Drive exchange from Linux uses rclone:

```bash
bash scripts/rclone/pull-agent-packages.sh
bash scripts/rclone/push-user-result.sh /path/to/result.tar.zst
```

Install the built APK directly from Linux when needed:

```bash
bash scripts/device/install-debug-apk.sh
```

There is no Termux checkout or rsync stage. See `COLLABORATION_PROTOCOL.md` for exact boundaries.
