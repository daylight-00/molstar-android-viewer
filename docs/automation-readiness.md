# Automation and release readiness

This repository is prepared so that GitHub Actions can remain a thin orchestration layer. The workflow YAML files and GitHub Release publication are intentionally not present yet.

## Channels

| Channel | Application ID | Purpose |
|---|---|---|
| stable release | `io.github.daylight00.molstarandroid` | last device-approved build |
| candidate release | `io.github.daylight00.molstarandroid.candidate` | automated upstream candidate installed beside stable |
| candidate debug | `io.github.daylight00.molstarandroid.candidate.debug` | local development and smoke testing |

The stable and candidate release variants use the same optional sideload signing contract. Candidate is isolated by application ID, so it cannot overwrite stable.

## Canonical inputs

The host version is tracked in `version.properties`; the Mol* version is tracked in the vendored `VERSION` file. CI may override Android package versioning with:

```text
MOLSTAR_ANDROID_VERSION_CODE
MOLSTAR_ANDROID_VERSION_NAME
```

Release signing is supplied only through environment variables or same-named Gradle properties:

```text
MOLSTAR_ANDROID_KEYSTORE_FILE
MOLSTAR_ANDROID_KEYSTORE_PASSWORD
MOLSTAR_ANDROID_KEY_ALIAS
MOLSTAR_ANDROID_KEY_PASSWORD
```

The keystore and passwords are never committed. A release script rejects incomplete signing input and verifies the resulting APK signature.

## Action entry points

A future workflow should only orchestrate these repository-owned commands:

```bash
# Pull-request and push CI
VERIFY_BUILD=always VERIFY_VARIANT=CandidateDebug bash scripts/verify.sh

# Build one bounded artifact directory
ARTIFACT_OUTPUT_DIR="$RUNNER_TEMP/candidate" \
  bash scripts/ci/build-channel.sh candidate release

# Scheduled upstream preparation on a bot branch
UPDATE_BUILD_TYPE=release UPDATE_OUTPUT_DIR="$RUNNER_TEMP/update" \
  bash scripts/automation/prepare-molstar-update.sh latest

# Device-approved stable release preparation
MOLSTAR_ANDROID_VERSION_CODE=<monotonic integer> \
RELEASE_OUTPUT_DIR="$RUNNER_TEMP/release" \
  bash scripts/release/prepare-release.sh
```

`prepare-molstar-update.sh` may modify only `app/src/main/assets/viewer/vendor/molstar/**`. The scope gate rejects changes to Android integration, bridge, theme, or customization files. It emits a candidate artifact and a machine-readable update report but does not commit, push, or create a pull request.

`prepare-release.sh` requires a clean `main`, explicit monotonic `versionCode`, complete signing input, a signed stable APK, and an artifact manifest. It emits release notes and a release manifest but does not create a tag or GitHub Release.

## Local Actions simulation

The full build/sign/stage path can be exercised without a permanent key:

```bash
bash scripts/ci/simulate-actions.sh
```

The simulation creates an ephemeral two-day keystore, builds signed candidate and stable release APKs, verifies manifests and signatures, tests the Layer 1 update-scope gate, then deletes the temporary key. It proves pipeline behavior but cannot prove that the real long-lived signing key is safely backed up.

## Remaining work

The next stage is limited to:

1. create and offline-backup the permanent sideload keystore;
2. add its encoded bytes and passwords as GitHub repository secrets;
3. add workflow YAML that calls the scripts above;
4. configure artifact retention, bot branch/PR updates, manual promotion, tags, and GitHub Releases.

No application architecture change should be required for that stage.
