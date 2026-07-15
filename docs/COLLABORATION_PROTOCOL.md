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

Assistant-to-user and user-to-assistant exchanges use one `.tar.zst` per direction whenever practical.

Assistant-to-user packages normally contain:

```text
patch or bundle
manifest and SHA-256 inventory
expected base HEAD/tree
one APPLY_AND_RUN.sh wrapper
rollback or backup instructions
```

User-to-assistant result packages normally contain:

```text
complete stdout and stderr
raw return codes
pre/post HEAD and tree
build APK and SHA-256 when produced
machine-readable result index
safety bundle metadata
```

The assistant uses the Google Drive connector. The Linux workstation uses rclone against the same folders:

```text
HW-T/molstar-android-viewer/exchange/agent-to-user
HW-T/molstar-android-viewer/exchange/user-to-agent
```

Default helper commands:

```bash
bash scripts/rclone/pull-agent-packages.sh
bash scripts/rclone/push-user-result.sh /path/to/result.tar.zst
```

The rclone remote defaults to `gdrive` and can be changed with `RCLONE_REMOTE`. This transport does not pass through Termux or the Android filesystem.

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
10. assistant retrieves and independently audits it through the Drive connector
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

Use `PUBLISH=1` only when the current gate is ready for GitHub publication.

## Android device boundary

The Android device is not a repository or transport node. APK installation is driven from Linux through adb:

```bash
bash scripts/device/install-debug-apk.sh
```

Future runtime-evidence wrappers should invoke adb from Linux, collect outputs into the Linux result root, and then package and upload those outputs with rclone.

## Claim boundary

A successful Gradle build proves source/build integration on the Linux workstation. It does not prove installation, WebView GPU behavior, touch interaction, file-intent handling, or runtime stability on an Android device. Those require separately preserved adb-driven device evidence.

## Reference

This protocol adapts the authority, package, and audit model used by `daylight-00/cpython-android-cli`, while using a Linux workstation instead of Termux and rclone instead of direct device transport.
