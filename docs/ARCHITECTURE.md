# Architecture

## Purpose

JACKAL Omarchy Edition is a presentation and operator integration for the
separately released JACKAL mathematical evidence kernel. It makes assurance
state visible at the desktop boundary without becoming another calculator or
certificate checker.

The separation is deliberate:

- the JACKAL repository owns mathematical implementation, tool schemas,
  certificate checkers, domain packs, runtime packaging, and evidence classes;
- this repository owns the Omarchy shell surface, local process adapters,
  optional recall ledger, operator diagnostics, and documentation;
- the operator owns verification expectations, runtime installation policy,
  update decisions, and consequential use.

## System context

```text
AI client
   │ JSON-RPC over stdio
   ▼
optional jackal-mcp-ledger ───────────────► local results.jsonl
   │ byte-transparent forwarding                 │ recall only
   ▼                                             ▼
identity-pinned Codex adapter ─► JACKAL MCP launcher ─► private runtime snapshot
    │ additive THOTH/CAS/STEM          │                    │ sealed tools
    │ wrappers delegate numeric fields│                    │
    └─────────────────────────────────┴──── structured results
                                                        │
                                                        ▼
Omarchy dropdown ◄────── local files/process output ─ operator CLI
       │
       └── verify_artifact.py ─► JACKAL receipt/bundle front door
                ▲
                └── operator expectations, never artifact-derived
```

No arrow from the UI grants mathematical assurance. The UI copies returned
classes and can route an artifact to a checker, but the checker remains the
authority for its own verdict.

The Codex package's declared 58-name surface is composed of the sealed
41-tool runtime plus identity-pinned additive THOTH, advanced, and STEM
wrappers. This composition is package metadata. The operator's finite doctor
run probes selected sealed-runtime evidence families; it does not convert the
surface declaration into universal function evidence. Additive wrapper output
keeps its own status, assumptions, consequence ceiling, delegation trace, and
non-claims.

## Components

### `Panel.qml`

The root Omarchy `bar-widget` entry point. It owns panel lifecycle, keyboard and
mouse interaction, the stable scroll plane, graph preview, evidence register,
latest-result card, and pinned non-claim footer.

It preserves existing behavior:

- left click toggles;
- right click probes;
- middle click verifies the runtime;
- Escape closes;
- panel switching follows Omarchy's bar contract;
- keyboard shortcuts remain available while the panel has focus.

The reading plane is opaque, device-pixel aligned, and rendered without layer
smoothing so glyphs do not shimmer during vertical scrolling.

### `Service.qml`

The outer adapter for local processes and files. It:

- starts the bundled operator CLI;
- reads the generated capability inventory from the runtime named by the doctor
  payload;
- watches the optional ledger for changes;
- reads the runtime's governing non-claim;
- sends clipboard or retained artifacts to `verify_artifact.py`;
- copies user-selected text through `wl-copy`.

All process invocations use argument arrays, not a shell command string. A
failed or unparsable run clears prior state instead of leaving a stale pass on
screen.

### `Model.js`

A QML-compatible pure JavaScript module. It parses bounded local inputs and
maps them to display state. Its important invariants are covered by Node tests:

- missing evidence is `indeterminate`, never affirmative;
- an identity mismatch is a refusal;
- stale observations do not remain current;
- a consequence cap is not a failure and is not an assurance upgrade;
- `exact` and `formal-bounded` keep their declared ordering and distinct
  meanings;
- malformed ledger lines do not create results;
- retained receipts remain recall until re-verified.

### `bin/omarchy-jackal`

The bundled operator CLI discovers the installed runtime through the JACKAL
runtime locator or an explicit `JACKAL_HOME`. It separates:

1. **presence** — package metadata and runtime files were observed;
2. **integrity** — the identity-pinned JACKAL provisioner accepted the pinned
   checksum inventory and runtime self-test;
3. **function** — canonical tools executed during the current doctor run at
   classes declared by the installed capability inventory.

The CLI does not carry a fallback verifier. If the core provisioner cannot be
found or its plugin identity refuses, runtime verification refuses.

### `verify_artifact.py`

Routes a `jackal-formal-receipt-v1` or `jackal-claim-bundle-v1` to the
corresponding JACKAL verification front door. Artifact parsing and expectation
loading are separated so expectation values cannot be copied from the artifact
inside the request-construction function.

Input size, schema, time, path, and output handling are bounded. Widget-origin
failures have `widget-*` reasons so they cannot be mistaken for a JACKAL
verification verdict.

### `bin/jackal-mcp-ledger`

An optional stdio proxy. It forwards bytes first, flushes immediately, and
records a best-effort copy after forwarding. It retains formal receipt objects
by digest so they can later be rechecked. The row in `results.jsonl` remains
recall, even when it contains a digest or exact-looking number.

The wrapper serializes concurrent ledger updates, bounds history, bounds prose,
keeps full rational enclosure endpoints or omits them, and rounds displayed
decimal bounds outward.

## Filesystem and ownership

| Path | Owner | Trust meaning |
|---|---|---|
| `~/.config/omarchy/plugins/khephri.jackal` | Omarchy/user | Executable plugin source |
| `~/.config/jackal-omarchy/config.json` | Operator | Optional local path policy |
| `~/.config/omarchy/jackal-expectations.json` | Operator | Verification authorization |
| `~/.local/share/JACKAL/codex-plugin/runtime.json` | JACKAL provisioner | Runtime locator; validated before use |
| `~/.local/share/JACKAL/runtimes/<epoch>` | JACKAL provisioner | Installed runtime tree |
| `~/.local/state/jackal/results.jsonl` | Ledger wrapper | Recall only |
| `~/.local/state/jackal/receipts/` | Ledger wrapper | Retained artifacts; not verified merely by storage |

The plugin never commits or ships an operator expectations file, runtime
locator, ledger, receipt, or installed package.

## State model

| Display state | Required observation |
|---|---|
| `FUNCTIONAL` | Fresh doctor run, identity self-test match, and every executed canonical family at its declared class |
| `DEGRADED` | A probe ran but at least one declared function or identity condition failed |
| `REFUSED` | Runtime verification, identity, routing, or operator policy refused |
| `STALE` | Prior probe exceeded the configured freshness window |
| `INDETERMINATE` | Current inputs establish neither pass nor refusal |
| `NOT INSTALLED` | No valid runtime location was observed |

Presence alone cannot produce `FUNCTIONAL`.

## Network boundary

Normal panel operation performs no network request. Omarchy installation and
updates use Git because the Omarchy plugin manager clones the public repository.
JACKAL runtime provisioning and Codex plugin installation have their own
documented network and pinning behavior in the core repository.

## Failure strategy

- Unknown input schema: refuse or clear state.
- Missing runtime: show not installed.
- Missing core provisioner: runtime verification refuses.
- Unreadable ledger: show no recent results.
- Unparsable doctor output: replace the previous report with an error.
- Unsupported artifact: return a named widget refusal.
- Verification mismatch: carry the front door's refusal verbatim.
- Graph evaluation failure: no proof claim is minted.

The architecture intentionally prefers a visible absence of assurance over a
plausible stale answer.
