# Security policy

## Supported versions

Security fixes are applied to the current `main` branch and, after the first stable publication, to the latest stable release. Development artifacts and superseded candidate builds are not maintained as security-supported releases.

## Reporting a vulnerability

Do not disclose a suspected vulnerability in a public issue, pull request, discussion, or log attachment.

Use GitHub's **Report a vulnerability** control on this repository's Security page. Private vulnerability reporting keeps the report and follow-up discussion visible only to the reporter and repository maintainers until coordinated disclosure is appropriate.

Include, when available:

- the affected app version, channel, and commit;
- Android and System WebView versions;
- clear reproduction steps;
- the security impact and required user interaction;
- whether the behavior is also reproducible in the official Mol* web Viewer;
- a minimal non-sensitive test file or proof of concept.

Do not include real credentials, private molecular structures, medical data, or other confidential files. Use synthetic or minimized test data.

## Upstream boundary

The Mol* Viewer runtime is vendored without source modifications. A vulnerability may therefore belong to:

- this Android host and its native integration;
- the Android System WebView or platform;
- the upstream Mol* Viewer runtime;
- an interaction between those layers.

Report the issue here first when the Android package or integration is involved. The maintainer will coordinate with upstream projects where necessary rather than requiring the reporter to disclose the same issue publicly in multiple places.

## Signing material

Release keystores, passwords, tokens, and decoded secret values must never be attached to an issue or committed to the repository. A package signed with an unexpected certificate should be treated as untrusted until its provenance is resolved.
