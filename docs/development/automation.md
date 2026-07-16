# GitHub Actions and release automation

The repository now contains the complete unattended update and CI release path. Workflow YAML is intentionally thin: Android, update, signing, artifact, and release logic remains in repository-owned scripts that can be reproduced in a local checkout.

## Workflows

| Workflow | Trigger | Permission boundary | Result |
|---|---|---|---|
| `ci.yml` | push, pull request, manual | `contents: read` | verifies the repository and uploads a candidate-debug artifact |
| `molstar-update.yml` | weekly schedule, manual | `contents: write`, `pull-requests: write` | replaces Layer 1 only, builds a signed candidate, pushes a version branch, opens a PR |
| `promote.yml` | manual only | `contents: write` | verifies the device-approved commit, builds stable, and publishes a GitHub Release |

The update workflow uses one branch per target Molstar version, for example `automation/molstar-5.11.0`. It never force-pushes. If the target branch already exists, the workflow reports the existing candidate instead of rewriting it.

## Channels

| Channel | Application ID | Purpose |
|---|---|---|
| stable release | `io.github.daylight00.molstarandroid` | last device-approved build |
| candidate release | `io.github.daylight00.molstarandroid.candidate` | signed upstream candidate installed beside stable |
| candidate debug | `io.github.daylight00.molstarandroid.candidate.debug` | ordinary push/PR CI and local smoke testing |

## Repository-owned entry points

```bash
# Push/PR CI artifact
ARTIFACT_OUTPUT_DIR=artifacts/ci-candidate-debug \
  bash scripts/ci/build-channel.sh candidate debug

# Weekly upstream preparation
UPDATE_BUILD_TYPE=release UPDATE_OUTPUT_DIR=artifacts/molstar-update \
  bash scripts/automation/prepare-molstar-update.sh latest

# Device-approved stable artifact
RELEASE_OUTPUT_DIR=artifacts/release \
  bash scripts/release/prepare-release.sh

# GitHub Release publication or local publication dry-run
PUBLISH_DRY_RUN=1 \
  bash scripts/release/publish-github-release.sh artifacts/release/release-manifest.json
```

`prepare-molstar-update.sh` may modify only `app/src/main/assets/viewer/vendor/molstar/**`. Any change to Android integration, the JavaScript bridge, theme handling, customization, build logic, or workflow logic fails the scope gate.

## Version policy

`version.properties` and the vendored Molstar `VERSION` are the canonical names. No CI script contains a hard-coded host version string.

GitHub run numbers are mapped into disjoint Android version-code bands:

```text
stable:    1,000,000,000 + promote workflow run number
candidate: 1,100,000,000 + update workflow run number
simulation: 900,000,000 + HOST_VERSION_CODE
```

The real stable band is above all previous simulation builds, while remaining below Android's maximum version code. Candidate uses a separate application ID and its own band.

## Local Actions simulation

```bash
bash scripts/ci/simulate-actions.sh
```

The simulation creates an ephemeral two-day keystore, builds signed candidate and stable APKs, verifies manifests and signatures, checks the update boundary, and performs a dry-run of GitHub Release publication. The generated version name is derived from `version.properties`, so host version bumps cannot leave CI artifact names behind.

## Initial activation

One permanent signing identity is still an external prerequisite. Configure it once from a trusted local workstation:

```bash
bash scripts/release/configure-github-signing.sh
```

The script creates or reuses the offline keystore and sets these encrypted repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

After the secrets exist, the scheduled update workflow can publish signed candidates. Stable release remains intentionally manual and requires the exact full SHA that was installed and approved on a real Android device.
