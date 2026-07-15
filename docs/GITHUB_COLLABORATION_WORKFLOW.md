# Git, Linux, Drive, and Android collaboration workflow

The active workflow is defined in [`COLLABORATION_PROTOCOL.md`](COLLABORATION_PROTOCOL.md).

This compatibility entry keeps the familiar filename used by other HW-T repositories. The Linux workstation is the only checkout/build/transport host. The Android device is accessed through adb only when runtime validation is required; Termux is not part of this project workflow.

Assistant handoffs follow the single-runner rule: after one manual `rclone copyto`, all checksum, extraction, repository mutation, build, evidence packaging, and result upload steps are executed by the downloaded Bash runner.

Verified runner changes use normal fast-forward publication to `origin/main` by default. Remote divergence, failed `gh` authentication, or a mismatched remote readback stops publication and is preserved in the result archive. Force push is outside the ordinary workflow.
