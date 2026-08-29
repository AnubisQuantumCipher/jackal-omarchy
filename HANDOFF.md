# JACKAL Omarchy Edition handoff

This is the continuation record for the JACKAL + THOTH Omarchy plugin. It is
not a certificate. Commands and GitHub states are observations; mathematical
and formal claims keep the evidence class returned by their governing checker.

## Mission and invariants

The plugin extends the existing JACKAL foundation without replacing the bar
dropdown or changing its interaction contract. Preserve:

- plugin ID `khephri.jackal`, visible name `JACKAL + THOTH`, and `Panel.qml`
  bar-widget entry point;
- the current open/close, scrolling, keyboard, mouse, graph, linked-workspace,
  evidence-register, and latest-results behavior;
- THOTH as JACKAL's integrated measurement/provenance subsystem, never a
  separate authority;
- every returned JACKAL status, refusal reason, consequence ceiling, and
  non-claim without promotion;
- graph pixels as visualization only, never proof or evidence;
- explicit separation of installed presence, pinned runtime integrity, and
  function sampled in the current doctor invocation.

Do not claim NASA, SpaceX, Omarchy, FAA, Texas Instruments, or another
organization has endorsed, certified, qualified, or approved the project.

## Repositories and live installation

- Plugin source: `<workspace>/Projects/jackal-omarchy`
- JACKAL core source: `<workspace>/Projects/jackal`
- Live plugin: `$HOME/.config/omarchy/plugins/khephri.jackal`
- Public plugin repository:
  <https://github.com/AnubisQuantumCipher/jackal-omarchy>
- Marketplace submission:
  <https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/3232>

The plugin and core repositories stay separate. A plugin release must not
rename, rebuild, or imply a new mathematical runtime epoch.

## Public state before the current release candidate

The public repository contains the released `v2.6.1` line. GitHub hosts a
non-draft release whose public-download archive passed its detached digest and
matched the locally validated tag artifact byte for byte. The tag workflow
passed the mandatory assurance gate and independent release reproduction.

The marketplace submission is open. Its structure validator recognizes
`khephri.jackal` at `v2.6.1`; the marketplace baseline treats any fetched
source execution as requiring manual review even when the fetch is commit-
pinned. Eliminating fetched-source execution is the reason for the `v2.6.2`
candidate. Maintainer listing approval remains an external pending action after
the superseding release is submitted.

Do not move or rewrite the existing tag. Publish a new version for corrections.

The current GitHub CLI session uses browser/device-flow authentication from the
system keyring. Never use, repeat, store, or commit any credential pasted into
chat. The current OAuth session was deliberately refreshed to authorize the
pinned workflow push. Continue to use the system keyring or device flow only.

## Current local release candidate

The local version is `2.6.2`. The additive assurance implementation is
published in `v2.6.1`; the local tree-materialization correction is not yet
published:

- `formal/src/jackal_assurance_policy.*`: pure SPARK finite policy kernel;
- `formal/prove.sh`: fail-closed GNATprove gate;
- `formal/tests/jackal_assurance_vectors.adb`: exhaustive vector emitter;
- `tests/formal_conformance.test.mjs`: shipped-JavaScript differential gate;
- `assurance/requirements.json`: machine-readable bidirectional traceability,
  claim status, and residuals;
- `scripts/check-traceability.py`: duplicate-key and two-way link enforcement;
- `scripts/check-formal.sh`: optional developer / mandatory release proof lane;
- `scripts/check-release-reproducibility.sh`: independent clean-checkout byte
  comparison;
- `scripts/release-gate.sh`: mandatory release checks;
- `.github/workflows/assurance.yml`: pinned public automation;
- `docs/PLATINUM_ASSURANCE.md`: standards-facing claim and boundary.

The packaging defect in the earlier release path was traced to volatile GNU
tar POSIX PAX access/change-time records. `scripts/package-release.sh` now
removes those records and accepts only an absolute canonical release-output
directory. The `v2.6.2` harness materializes the validated local commit into
two independent repositories and verifies exact Git tree identity before
either checkout executes; it performs no clone, fetch, remote, or shared-
worktree operation.

The doctor now emits a failing row for every undeclared canonical probe. It
cannot report `FUNCTIONAL` merely because a partial inventory contains one
passing probe. Positive, wrong-status, missing-probe, and identity-failure cases
are unit tested.

## Formal claim boundary

The local GNATprove run discharged every reported obligation for
`Jackal_Assurance_Policy`, including its functional postconditions, termination,
and targeted run-time checks. The gate rejects any unproved or justified check
and rejects `pragma Assume` and `pragma Annotate` in the formal tree.

The claim is component-scoped SPARK Platinum for these allocated requirements:

- `JOP-STATE-001`
- `JOP-STATE-002`
- `JOP-ASSURANCE-001`
- `JOP-CAP-001`
- `JOP-DOCTOR-001`

The full QML/JavaScript/Python/shell/Linux plugin remains
`product_claim.status=not-established`. Exhaustive differential conformance is
strong bridge evidence, not a formal source-to-source refinement proof. Read
`docs/PLATINUM_ASSURANCE.md` and `assurance/requirements.json` before changing
or describing the claim.

## Mandatory local gates

Development gate:

```sh
./scripts/check.sh
```

Release gate, which refuses to skip GNATprove:

```sh
./scripts/release-gate.sh
```

Direct proof and bridge reproduction:

```sh
./formal/prove.sh
node tests/formal_conformance.test.mjs
```

Traceability is two-way: every baseline link must name an existing regular file,
and every linked file must cite the requirement ID. Do not bypass this by
weakening the validator or deleting a residual.

## Publication procedure

Before publication:

- run `git diff --check`, inspect every diff, and confirm no generated proof
  objects or runtime artifacts are tracked;
- run the mandatory release gate from the exact committed tree;
- inspect the archive path list and validate its internal `MANIFEST.sha256`;
- install the candidate into a backed-up live Omarchy plugin directory and run
  validation, rescan, open/close, doctor, verify, graph, linked-workspace,
  latest-result, stale-state, and scroll-stability checks;
- refresh GitHub authentication only through `gh auth refresh` so the pinned
  workflow can be pushed; never inject a chat credential;
- push main, wait for the public assurance workflow, tag the exact reviewed
  commit, rebuild from the tag, compare release bytes, then publish the archive
  and digest;
- update marketplace issue `3232` so validation targets the new exact commit.

Use a signed tag only when a configured signing identity is available. An
unsigned tag or checksum is transport integrity, not publisher authentication.

## Core JACKAL continuation

The core feature branch now contains two surgical assurance commits. The first
allocates and proves the complete fixed-scale HELLGATE interval-admission
kernel, adds bidirectional requirements traceability, and makes its GNATprove
gate fail on assumptions, justifications, warnings, or skipped units. The
second adds a total SPARK claim-assurance policy kernel for finite axis meets,
rule caps, and artifact conjunction, together with exhaustive differential
vectors against both the producer and independently isolated verifier.

Those commits do not absorb or overwrite the broader dirty worktree, which
contains unrelated ongoing core, Codex-plugin, measurement, graphing, and STEM
changes. Do not reset or mass-stage that tree. Whole-JACKAL Platinum still
requires specification and refinement closure across every published tool,
parser, wrapper, checker, runtime, compiler, and platform assumption.

## Non-claims

- A finite doctor probe is not universal mathematical correctness.
- A local ledger row is recall, not evidence.
- A graph is not proof.
- An exact mathematical result is informational about software correctness
  unless separate program evidence supports a stronger conclusion.
- A SPARK component proof does not certify the mixed-language plugin.
- Reproducible source bytes do not authenticate the publisher.
- Marketplace validation is not a security audit, certification, warranty, or
  engineering endorsement.
- No current artifact establishes flight qualification or suitability for a
  safety-critical deployment.
