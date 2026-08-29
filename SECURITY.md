# Security Policy

## Supported versions

Security fixes are applied to the current release line. Older snapshots remain
available for audit but may not receive fixes.

## Report privately

Do not open a public issue for a vulnerability, exposed credential, malicious
artifact, unsafe command execution, or private data disclosure. Use GitHub's
private vulnerability reporting for the public repository. If private reporting
is unavailable, contact the repository owner through a non-public channel shown
on the GitHub organization profile.

Include the affected commit or release, Omarchy version, JACKAL runtime epoch,
host architecture, observed behavior, and the smallest safe reproduction.
Remove tokens, private receipt contents, operator expectations, home paths, and
personal data.

## Credential handling

Never paste a personal access token, API key, SSH private key, signing key, or
session cookie into chat, issues, logs, screenshots, or repository files. A
credential disclosed in any of those places must be revoked and replaced; it
must not be reused merely because the message was later deleted.

This repository does not require a GitHub token at runtime. Release automation
uses GitHub's short-lived workflow token with least-required permissions.

## Security boundaries

- Omarchy plugins execute unsandboxed as the current user.
- The panel starts only bundled or local commands and does not use `sudo` or
  `pkexec`.
- Clipboard artifacts are untrusted and bounded before parsing.
- Verification expectations are operator-owned and structurally separate from
  the artifact.
- Ledger files are recall and may be edited by the user; they are not trusted as
  evidence.
- Runtime integrity checks delegate to the identity-pinned JACKAL provisioner.
- Plugin updates clone mutable upstream `HEAD` unless the user installs an exact
  reviewed commit. Marketplace verification applies only to its recorded commit.

See `docs/THREAT_MODEL.md` for assets, actors, entry points, mitigations, and
residual risks.

## Non-claims

Marketplace validation, CI, static analysis, review, and runtime self-tests are
not a security certification, mathematical proof, warranty, or guarantee of
suitability for consequential use.
