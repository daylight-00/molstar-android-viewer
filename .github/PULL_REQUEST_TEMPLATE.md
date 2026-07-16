## Summary

Describe the user-visible or maintenance problem and the chosen solution.

## Architectural layer

- [ ] Layer 1: upstream Mol* runtime replacement only
- [ ] Layer 2: Android platform integration or bridge
- [ ] Layer 3: minimal mobile customization policy
- [ ] Build, verification, automation, or documentation

## Verification

- [ ] `bash scripts/verify.sh`
- [ ] Relevant candidate APK built
- [ ] Real-device test performed, or explicitly marked as not performed
- [ ] No upstream generated JavaScript or CSS was patched
- [ ] No keystore, credential, token, private structure, or confidential diagnostic data is included

Device evidence and desktop/CI evidence must be reported separately.

## Upstream and release impact

State whether the change replaces the Mol* runtime, changes application behavior, affects signing/versioning, or requires release notes.
