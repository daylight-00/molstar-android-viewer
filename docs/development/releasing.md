# Signing and release contract

Android accepts an update to an installed application only when the application ID and signing identity match. Stable therefore uses one long-lived sideload key. Candidate has a different application ID but uses the same permanent key to keep one developer identity and permit candidate upgrades.

## One-time permanent key and GitHub Secrets

Run this only on a trusted local workstation:

```bash
bash scripts/release/configure-github-signing.sh
```

The helper creates or reuses:

```text
$HOME/.local/share/molstar-android-viewer/sideload.jks
```

It prompts for passwords without printing them, validates the alias, and writes the keystore bytes and credentials to encrypted GitHub repository secrets. Keep at least one encrypted offline backup outside the repository and record the passwords in a password manager.

The configured secret names are:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Workflows decode the keystore only under `$RUNNER_TEMP`; it is never committed or uploaded as an artifact.

## Play Protect and sideloaded builds

An APK installed outside Google Play can trigger a Play Protect scan or unknown-app prompt, especially when Google has not evaluated that exact APK before. A scan recommendation is not the same as a harmful-app verdict. A message that explicitly says the app is harmful, blocked, or removed is a release failure and must be investigated before distribution.

Every invocation of `scripts/ci/simulate-actions.sh` creates a new ephemeral certificate. Those APKs are test artifacts only and cannot update builds signed by another simulation key. The permanent key establishes a stable Android update identity, although it cannot guarantee that Play Protect will never scan an APK distributed outside Google Play.

## Version policy

The default stable name embeds host and upstream versions:

```text
0.2.1-molstar.5.10.1
```

Scheduled candidates append workflow identity before Gradle adds the candidate flavor suffix:

```text
0.2.1-molstar.5.11.0-ci.42-candidate
```

Stable version codes use `1,000,000,000 + promote run number`; candidate version codes use `1,100,000,000 + update run number`. These bands are above previous ephemeral simulation builds and are monotonically increasing within each workflow.

## Candidate update flow

`molstar-update.yml` runs weekly and can also be dispatched manually. When a newer upstream version exists it:

1. replaces the official Viewer runtime as one unit;
2. rejects every change outside `vendor/molstar/**`;
3. builds a signed candidate release;
4. pushes a new non-force-updated automation branch;
5. opens a PR and stores the APK, manifest, provenance, and checksums for 90 days.

The candidate is installed beside stable and must be used on a real device before merging or promotion.

## Upstream naming and branding gate

Stable publication remains blocked while `UPSTREAM_NAMING_STATUS=pending` in `project.properties`. Record the permanent upstream discussion URL and the resulting guidance in [`docs/project/naming-and-branding.md`](../project/naming-and-branding.md), then change the status to `approved` in the same reviewed commit. Code licensing under MIT does not by itself grant logo or trademark permission.

## Human promotion gate

After the upstream naming gate is approved and the candidate commit on `main` has been installed and approved, run:

```bash
gh workflow run promote.yml \
  --repo "$(gh repo view --json nameWithOwner --jq .nameWithOwner)" \
  -f approved_commit="$(git rev-parse HEAD)"
```

The workflow refuses a short SHA or a SHA different from current `main`. It then builds a signed stable APK, prepares manifests and release notes, and publishes or idempotently repairs the corresponding GitHub Release.

The stable release includes:

```text
signed APK
artifact-manifest.json
release-manifest.json
release-notes.md
SHA-256 inventories
```
