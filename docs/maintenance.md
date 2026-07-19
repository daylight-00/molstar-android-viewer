# Maintenance and releases

## Upstream Mol* updates

The vendored version is recorded in `app/src/main/assets/viewer/vendor/molstar/VERSION`. Replace it with:

```bash
bash scripts/sync-molstar-assets.sh <version>
bash scripts/verify.sh
```

The synchronization script downloads the npm release, replaces the complete prebuilt Viewer runtime, records provenance, and regenerates checksums. Do not edit vendored files by hand.

The compatibility checks cover only the public surface required by the host, including `Viewer.create`, `viewer.loadFiles`, URL/PDB commands used by `app-bridge.js`, and the default and dark stylesheets.

## Automation

| Workflow | Trigger | Result |
|---|---|---|
| `ci.yml` | push, pull request, manual | candidate debug artifact |
| `molstar-update.yml` | weekly, manual | bounded upstream-update branch and candidate |
| `promote.yml` | manual | signed stable GitHub Release |

Workflow YAML remains thin; build, update, signing, and publication logic lives in repository scripts so it can also run locally.

Useful entry points:

```bash
bash scripts/ci/build-channel.sh candidate debug
bash scripts/automation/prepare-molstar-update.sh latest
bash scripts/ci/simulate-actions.sh
bash scripts/release/prepare-release.sh
```

Automated upstream preparation is restricted to `app/src/main/assets/viewer/vendor/molstar/**` and never force-pushes an existing update branch.

## Signing and stable releases

Stable Android updates require the same application ID and long-lived signing identity. Candidate builds use a separate application ID so they can be installed beside stable.

Configure repository signing secrets from a trusted workstation with:

```bash
bash scripts/release/configure-github-signing.sh
```

The helper manages the permanent keystore outside the repository and configures the encrypted GitHub secrets expected by the workflows.

Stable promotion is manual. The workflow accepts only the full commit SHA currently at `main`, and that exact commit must first be installed and approved on a real Android device.

```bash
gh workflow run promote.yml \
  --repo "$(gh repo view --json nameWithOwner --jq .nameWithOwner)" \
  -f approved_commit="$(git rev-parse HEAD)"
```

Release outputs include the signed APK, artifact and release manifests, release notes, checksums, and signing-certificate identity.
