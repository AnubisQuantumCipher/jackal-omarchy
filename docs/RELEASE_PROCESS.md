# Release Process

## Version domains

The Omarchy integration version in `VERSION` and `manifest.json` is independent
from the JACKAL runtime epoch. A UI release must not rename, rebuild, or imply a
new core runtime release.

Semantic versioning applies to the plugin:

- patch: compatible bug, documentation, or test correction;
- minor: additive capability or operator workflow;
- major: incompatible plugin, configuration, or interaction contract.

## Release prerequisites

- Working tree changes are understood and reviewed.
- `VERSION`, manifest version, changelog, and release notes agree.
- Root README contains install and removal instructions.
- License and dependencies are current.
- Root `preview.png` was captured from the actual plugin and inspected.
- No secrets, operator authorization, receipts, ledgers, or local runtime paths
  are tracked.
- Mandatory formal local gate passes with no skipped proof.
- Live Omarchy validation and panel lifecycle pass on the supported host.
- Marketplace-required validation items are understood before submission.

## Local gate

```sh
JACKAL_REQUIRE_FORMAL=1 ./scripts/check.sh
```

Record commands and observed outputs in the release notes. Do not convert a test
count into a universal correctness claim.

## Build

After committing the exact release tree:

```sh
./scripts/package-release.sh
```

The script requires a clean Git tree, validates the version, uses `git archive`
as the source of release bytes, adds a sorted `MANIFEST.sha256`, and creates a
reproducible tar archive using the commit timestamp. It emits a separate SHA-256
file for transport integrity.

Before publishing, run the complete release gate:

```sh
./scripts/release-gate.sh
```

It adds the full ledger suite and checks `JOP-REL-001` by requiring the full
lowercase commit identity, initializing two empty checkouts, fetching only that
exact commit, checking it out detached, verifying `HEAD` again before either
checkout executes, building independently, comparing archive bytes and digest
files, and checking each digest. GNU tar POSIX PAX access/change-time records
are deleted so host filesystem metadata cannot perturb the archive.

## Tag and GitHub release

```sh
git tag -s "v$(cat VERSION)" -m "JACKAL Omarchy Edition v$(cat VERSION)"
git push origin main
git push origin "v$(cat VERSION)"
```

Use a signed tag when a configured signing identity is available. Do not claim
publisher authentication from an unsigned tag or a checksum alone.

Create the GitHub release manually from the tagged commit with
`RELEASE_NOTES.md` and the generated assets. Do not upload release bytes that
were built from a different commit.

## Marketplace submission

The community marketplace requires:

- a public GitHub repository;
- one root plugin with a valid manifest;
- root README and license;
- safe installation and removal instructions;
- a globally unique permanent plugin ID;
- optional root preview;
- exact category and one to three allowed tags;
- owner confirmation of every submission checklist item;
- exact-commit marketplace validation requested by the marketplace maintainers;
- explicit maintainer `approved-and-verified` decision.

Prepare the issue title and complete body, show both to the repository owner,
and obtain explicit approval before creating the issue. Marketplace approval is
listing approval, not security certification or engineering endorsement.

## Post-release

- Install from the public repository on a clean Omarchy user profile.
- Re-run validation, open/close, doctor, verify, stale state, and removal.
- Confirm the release archive digest and attached source commit.
- Confirm documentation links resolve on GitHub.
- Watch the pinned GitHub assurance workflow and marketplace validation results.
- Record any residual issue without rewriting the evidence from the release.

## Rollback

If a release is defective, do not move the existing tag. Publish a corrected
version, document the affected version, and restore the last reviewed plugin
commit locally. Marketplace update verification is exact-commit bound; follow
its update workflow for the corrected commit.
