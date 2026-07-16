# Signing and release contract

Android accepts an update to an installed application only when the application ID and signing identity match. The stable application therefore needs one long-lived sideload key. Candidate uses a different application ID but should use the same key to reduce secret management.

## One-time permanent key

Generate the permanent key on the canonical Linux workstation, not in GitHub Actions. Store at least one offline encrypted backup outside the repository. Do not use the ephemeral key created by `scripts/ci/simulate-actions.sh`.

Example command, with values chosen interactively and recorded in a password manager:

```bash
keytool -genkeypair \
  -keystore "$HOME/.local/share/molstar-android-viewer/sideload.jks" \
  -alias molstar-android-sideload \
  -keyalg RSA -keysize 3072 -validity 10000
```

Export the four signing inputs only for a local release build. Scripts never print password values.

```bash
export MOLSTAR_ANDROID_KEYSTORE_FILE="$HOME/.local/share/molstar-android-viewer/sideload.jks"
export MOLSTAR_ANDROID_KEYSTORE_PASSWORD='...'
export MOLSTAR_ANDROID_KEY_ALIAS='molstar-android-sideload'
export MOLSTAR_ANDROID_KEY_PASSWORD='...'
```

For GitHub Actions, store the keystore bytes as an encrypted secret, decode them into `$RUNNER_TEMP`, and point `MOLSTAR_ANDROID_KEYSTORE_FILE` at that temporary path. The workflow should delete it through normal runner teardown and never upload it as an artifact.

## Play Protect and sideloaded builds

An APK installed outside Google Play can trigger a Play Protect scan or unknown-app prompt, especially when Google has not evaluated that exact APK before. A scan recommendation is not the same as a harmful-app verdict. A message that explicitly says the app is harmful, blocked, or removed must be treated as a release failure and investigated before distribution.

Every invocation of `scripts/ci/simulate-actions.sh` creates a new ephemeral certificate. APKs produced by that simulation are test artifacts only: they do not accumulate a stable signing identity, cannot update a build signed by another simulation key, and must never be promoted as the long-lived stable release. The permanent sideload key is required before real CI release publication. Keeping one permanent certificate preserves Android update identity, but does not guarantee that Play Protect will never scan an APK distributed outside Google Play.

## Version policy

`version.properties` is the host baseline. Automated candidate builds should set a monotonically increasing `MOLSTAR_ANDROID_VERSION_CODE`, normally derived from the workflow run number. Stable promotion must use a value greater than every previously installed stable version code.

The default name embeds both host and upstream versions:

```text
0.2.1-molstar.5.10.1
0.2.1-molstar.5.10.1-candidate
```

CI may append run information by setting `MOLSTAR_ANDROID_VERSION_NAME` before Gradle configuration.

## Human promotion gate

A candidate is promoted only after installation on a real Android device. The bounded check is:

```bash
bash scripts/device/verify-candidate-apk.sh /path/to/candidate-release.apk
```

It installs the candidate beside stable, waits for Mol* readiness, opens a PDB through a content URI, rejects viewer error events, and preserves logs and a screenshot. Manual interaction should additionally cover rotation, theme switching, file picker behavior, and a representative real data set.
