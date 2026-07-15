# Upstream Mol*

- Package: `molstar`
- Vendored version: `5.10.1`
- Source: `https://github.com/molstar/molstar`
- License: MIT; copied to the vendor directory

The repository vendors only the official prebuilt viewer runtime required by the APK:

- `molstar.js`
- `molstar.css`
- viewer images and favicon

Source maps are intentionally excluded from the APK. Run `scripts/sync-molstar-assets.sh <version>` to update the vendor payload and regenerate checksums.
