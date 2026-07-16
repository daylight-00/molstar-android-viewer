# Collaboration protocol

## Purpose

This repository uses separate authorities for source, workstation builds, Android runtime evidence, and assistant transport.

```text
Git repository
  canonical source, documentation, scripts, and commit topology

Linux workstation
  canonical checkout and Android build environment
  default checkout: $HOME/projects/molstar-android-viewer-bootstrap
  default Android SDK: $HOME/opt/Android
  Git, gh, Gradle, rclone, and adb run here

Android device
  installation, interaction, performance, and runtime evidence only
  no Termux checkout, device-side Git workflow, SSH, rsync, or rclone requirement

Assistant environment
  exact repository reconstruction, narrow changes, verification, and package preparation

Google Drive
  connector-visible exchange of bounded .tar.zst packages and complete result archives
```

No layer substitutes for another.

## Authority order

For project state:

```text
1. canonical Git history and default-branch content
2. current collaboration, architecture, and handoff documents
3. exact package manifests, checksums, and machine-readable contracts
4. chat transcript as temporary coordination context
```

For behavior:

```text
complete Android-device evidence
  > successful Linux workstation build
  > static verification
```

## Git identity

Wrappers configure both global and repository-local identity:

```text
daylight-00 <hwjang00@snu.ac.kr>
```

Existing user-authored history is preserved. History is not rewritten without an exact backup bundle, explicit old/new identities, and remote lease checks.

## Drive and rclone exchange

The assistant and owner exchange bounded packages through these folders:

```text
HW-T/molstar-android-viewer/exchange/agent-to-user
HW-T/molstar-android-viewer/exchange/user-to-agent
```

The assistant uses the Google Drive connector. The Linux workstation uses `rclone`. Transport never passes through Termux or the Android filesystem.

### Single-runner handoff rule

For an assistant-to-user change, the only manual transport step is the first `rclone` download. The assistant uploads one self-contained Bash runner to `agent-to-user`. The runner embeds its patch or package payload, or fetches any companion objects itself.

The normal owner interaction is one compound command of this form:

```bash
rclone copyto \
  gdrive:HW-T/molstar-android-viewer/exchange/agent-to-user/<RUNNER>.sh \
  "$HOME/Downloads/<RUNNER>.sh" \
  --checksum && \
bash "$HOME/Downloads/<RUNNER>.sh"
```

Do not require separate manual checksum, extraction, directory-change, patch, Gradle, Git, result-packaging, or result-upload commands when they can be performed by the runner.

Each runner should, where applicable:

```text
verify its embedded manifest and payload hashes
verify expected branch, HEAD, tree, and clean worktree
set the approved global and repository-local Git identity
create a complete pre-change safety bundle
apply the bounded change and verify the resulting tree
run static verification and the required Android build
commit only after successful verification when the gate permits it
create a post-change bundle containing the resulting commit object
package complete PASS-or-FAIL logs and an exact result index
stage outgoing files below ~/Downloads before invoking rclone
upload the result archive and checksum to user-to-agent
print one final machine-readable status block
```

The first manual `rclone` download is the only routine exception to the single-runner rule.

User-to-assistant result packages normally contain:

```text
complete stdout and stderr
raw return codes
pre/post HEAD and tree
build APK and SHA-256 when produced
machine-readable result index
pre-change and post-change Git bundles
```

The default result helper stages any source archive under `~/Downloads/hw-t-rclone-staging/molstar-android-viewer` before upload. This avoids confinement failures when `rclone` cannot read hidden paths such as `~/.cache`.

```bash
bash scripts/rclone/push-user-result.sh /path/to/result.tar.zst
```

The rclone remote defaults to `gdrive` and can be changed with `RCLONE_REMOTE`.

## Standard bounded change

```text
1. reconstruct and verify the exact expected base
2. implement one narrow change
3. package one .tar.zst with one wrapper
4. wrapper verifies package checksum, HEAD, tree, and clean worktree
5. wrapper creates a safety bundle before mutation
6. wrapper applies the patch and verifies changed-file checksums
7. Linux workstation runs static verification and assembleDebug
8. PASS or FAIL evidence is packaged without being overwritten
9. Linux uploads the result archive with rclone
10. verified commits are fast-forward pushed to `origin/main` unless the gate explicitly disables publication
11. assistant retrieves and independently audits the result through the Drive connector
```

A failed build or device run remains evidence.

## Linux workstation build

```bash
cd "$HOME/projects/molstar-android-viewer-bootstrap"
bash scripts/linux-bootstrap-and-publish.sh
```

The SDK is resolved in this order:

```text
ANDROID_SDK_ROOT
ANDROID_HOME
ANDROID_SDK_CANDIDATE
$HOME/opt/Android
```

`PUBLISH=1` is the default for verified runner changes. Before push, the workflow verifies `gh` authentication, creates or resolves `daylight-00/molstar-android-viewer`, migrates a bootstrap bundle remote to `bootstrap-source`, and fetches `origin/main`, requires the remote head to be an ancestor of the local result, performs only a normal fast-forward push, and reads the remote ref back. Set `PUBLISH=0` only for an explicitly local gate.

## Android device boundary

The Android device is not a repository or transport node. APK installation is driven from Linux through adb:

```bash
bash scripts/device/install-debug-apk.sh
```

Runtime-evidence wrappers invoke adb from Linux, collect outputs into the Linux result root, and then package and upload those outputs with rclone.

The canonical smoke command is:

```bash
bash scripts/device/verify-debug-apk.sh
```

It installs the debug APK, starts the Activity, waits for the JavaScript `ready` event, copies a bounded PDB fixture to public Downloads, grants the Activity read access through an External Storage DocumentsProvider URI, waits for the `open-files` completion event, rejects viewer error events, and records logcat, screenshot, package state, device properties, current WebView provider, APK hash, and fixture hash.

## Claim boundary

A successful Gradle build proves source/build integration on the Linux workstation. It does not prove installation, WebView GPU behavior, touch interaction, file-intent handling, or runtime stability on an Android device. Those require separately preserved adb-driven device evidence.

## Reference

This protocol adapts the authority, package, and audit model used by `daylight-00/cpython-android-cli`, while using a Linux workstation instead of Termux and rclone instead of direct device transport.
