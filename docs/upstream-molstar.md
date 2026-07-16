# Upstream Mol*

- Package: `molstar`
- Vendored version: `5.10.1`
- Source: `https://github.com/molstar/molstar`
- License: MIT; copied into the vendor directory

## Ownership boundary

The upstream viewer is trusted as the molecular product layer. This repository does not attempt to maintain a fork or independently reproduce Mol* features. The vendored runtime is an immutable Layer 1 below Android integration and optional mobile adaptation.

Do not manually edit files under:

```text
app/src/main/assets/viewer/vendor/molstar/
```

The directory contains official prebuilt viewer runtime files, upstream license/provenance metadata, and `SHA256SUMS`. Source maps are excluded from the APK because they are development metadata, not runtime behavior.

## Upgrade

```bash
bash scripts/sync-molstar-assets.sh 5.11.0
bash scripts/verify.sh
```

The sync script downloads the named npm release, replaces the vendored `build/viewer` runtime as a unit, records npm provenance in `UPSTREAM.json`, and regenerates checksums.

The compatibility gate checks only the public surface required by the host:

- `window.molstar.Viewer.create`
- `viewer.loadFiles`
- explicit URL/PDB commands retained by `app-bridge.js`
- official default and dark stylesheets

A future upstream API change should normally require an adapter change in `app-bridge.js`, not edits to Android file-format logic or upstream assets.
