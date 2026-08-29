# Threat Model

## Scope

This model covers the Omarchy plugin, bundled operator CLI, artifact router, and
optional ledger wrapper. The mathematical soundness of JACKAL's core checkers
belongs to the core repository's assurance model.

## Assets

- integrity of displayed status classes, reasons, subjects, and non-claims;
- operator verification expectations;
- retained receipts and their private inputs;
- local clipboard contents;
- integrity and availability of the JACKAL runtime;
- Omarchy shell availability;
- user filesystem and credentials accessible to an unsandboxed plugin;
- exact marketplace-reviewed and release commits.

## Actors

- an ordinary local user operating the plugin;
- an accidental contributor introducing a laundering or availability bug;
- a malicious artifact author controlling clipboard or receipt bytes;
- another user process editing ledger or configuration files;
- a compromised upstream repository or mutable branch;
- a malicious or malformed runtime locator/package;
- a remote attacker who first gains the ability to modify user-owned files.

## Entry points

### QML process execution

The service starts fixed bundled paths and local runtime files using argument
arrays. It does not concatenate shell commands. Remaining risk includes a
compromised plugin checkout, runtime, or user environment.

### Clipboard artifacts

Clipboard bytes are attacker-controlled. The router applies size limits, schema
checks, bounded JSON parsing, strict field selection, time bounds, and named
refusal. Expectations arrive through a separate function input.

### Ledger files

Ledger rows are untrusted recall. The parser limits rows and fields and does not
execute content. Receipt paths are derived only from a strict hex digest, not
accepted from a ledger row.

### Runtime locator

The operator CLI requires an absolute canonical runtime path, rejects symlinked
roots and metadata, compares locator/package identity fields, validates the
capability inventory shape, and delegates full integrity verification to the
core provisioner.

### Core provisioner discovery

The CLI discovers the local `jackel` plugin through Codex or an operator-pinned
path, runs the plugin identity verifier, and then imports the provisioner with
bytecode disabled. Internal digest consistency is not publisher authentication;
the reviewed Git commit remains the external authority.

### MCP proxy

The ledger wrapper sits on the transport path. It forwards before observing,
uses no mathematical fallback, bounds retained data, locks concurrent writes,
and isolates the child session so ordinary client group termination becomes a
clean server EOF. A malicious wrapper source could still alter traffic because
it is unsandboxed; review and commit pinning are required.

### Upstream update

`omarchy plugin update` fetches mutable upstream state. Marketplace verification
is commit-bound and does not automatically cover a new head. Users should review
the diff and re-run acceptance before trusting an update.

## Security properties

1. No UI component mints a stronger JACKAL class.
2. Missing or malformed input cannot retain a prior affirmative state.
3. Artifact-derived data cannot populate operator expectation fields inside the
   router's request builder.
4. Ledger rows cannot choose filesystem paths for retained receipt verification.
5. Runtime integrity has no weaker local fallback.
6. No routine panel path requires privilege elevation.
7. No normal panel path downloads or executes remote content.
8. Credentials and live authorization data are excluded from the repository.

## Residual risks

- All Omarchy plugins share a long-lived unsandboxed user process.
- The operating system, filesystem, Python interpreter, Qt runtime, compiler,
  CPU, and supply chain are not formally verified here.
- Local user processes can edit user-owned state and replace a mutable checkout.
- Static marketplace scanning detects only documented patterns.
- Finite tests cannot establish absence of all vulnerabilities.
- Visual clarity can reduce but not eliminate human misinterpretation.
- The core provisioner's identity manifest is tamper evidence when anchored to
  a trusted revision; it is not publisher authentication by itself.

## Abuse cases and response

| Abuse case | Control | Residual response |
|---|---|---|
| Artifact carries its own expected answer | Separate operator expectations | Refuse mismatched authorization |
| Edited ledger claims `formal-bounded` | Recall label and re-verification | Re-run front door |
| Runtime path traverses or aliases | Canonical absolute path and symlink rejection | Refuse locator |
| Plugin update adds remote execution | Review, CI, marketplace exact-commit scan | Do not update; report privately |
| Old affirmative report survives a crash | Failed parse replaces state | Display refusal/indeterminate |
| Graph appears more certain than samples | Explicit `estimated` and pixels-not-proof labels | Use exact/bounded lane for conclusions |

## Out of scope

This document does not claim a complete adversarial analysis, a formal security
proof, a safety case, or compliance with a particular regulatory framework.
