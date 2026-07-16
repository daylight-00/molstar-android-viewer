# Developer documentation

This directory contains implementation and maintenance documentation for contributors.

## Read order

1. [Architecture](architecture.md)
2. [Upstream Mol* boundary and updates](upstream-molstar.md)
3. [GitHub Actions and automation](automation.md)
4. [Signing and releases](releasing.md)

General setup and contribution rules are in the repository-level [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Source map

```text
app/src/main/assets/viewer/vendor/molstar/  official upstream runtime
app/src/main/assets/viewer/app-bridge.js   stable Mol* Viewer adapter
app/src/main/assets/viewer/theme-controller.js
app/src/main/assets/viewer/customization.js
app/src/main/java/.../MainActivity.kt      Android lifecycle and file transport
scripts/ci/                                reproducible artifact builds
scripts/automation/                        bounded upstream updates
scripts/release/                           signing and publication
scripts/device/                            optional adb-based evidence
.github/workflows/                         thin orchestration only
```

Repository-owner transport and workstation-specific handoff procedures are maintained separately from the public source tree.
