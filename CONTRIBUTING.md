# Contributing

Thank you for improving JACKAL Omarchy Edition. Contributions are welcome for
the QML interface, pure JavaScript model, Python adapters, tests, documentation,
accessibility, packaging, and release engineering.

## Ground rules

1. Do not promote a JACKAL status or omit a returned non-claim.
2. Do not infer function from package presence or manifest metadata.
3. Treat ledger rows as recall, never evidence.
4. Keep verification expectations independent from the artifact under review.
5. Do not add silent fallback to a weaker mathematical lane.
6. Do not add network downloads or privileged operations to panel startup.
7. Do not commit credentials, receipts containing private inputs, authorization
   files, or local ledger contents.
8. Preserve the permanent plugin ID unless a marketplace migration has been
   designed and approved.

## Development setup

Fork and clone the repository, then run:

```sh
./scripts/check.sh
```

On Omarchy, validate against the installed schema:

```sh
omarchy plugin validate .
```

To test live without editing packaged Omarchy files, place the repository in a
user-owned plugin directory or install your fork with `omarchy plugin add`.
Saved files under `~/.config/omarchy/plugins/` hot-reload.

## Change expectations

- UI changes must preserve keyboard, mouse, Escape, panel-switching, and stable
  scrolling behavior.
- Status/model changes need unit tests for positive, refusal, malformed, stale,
  and missing-input cases.
- Process changes need bounded input/output handling and a named failure mode.
- Documentation must state external dependencies and any new filesystem,
  clipboard, process, network, or privilege capability.
- Visual assets must be owned or licensed for redistribution and must not imply
  mathematical assurance.

## Pull requests

Include:

- the user-visible outcome;
- the trust boundary affected;
- tests added or updated;
- commands executed and observed results;
- security and privacy impact;
- screenshots for visible changes;
- explicit residual risks or non-claims.

Do not describe a finite test run as proof of universal correctness.

## Reporting problems

Use a public issue for ordinary bugs and feature requests. Use the private
process in `SECURITY.md` for vulnerabilities, credential exposure, unsafe
execution, or privacy concerns.
