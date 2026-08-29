# Development Guide

## Repository layout

```text
manifest.json                 Omarchy plugin contract
Panel.qml                     bar entry point and dropdown
Service.qml                   process/file adapter
Model.js                      pure classification model
verify_artifact.py            receipt and bundle router
bin/omarchy-jackal            operator CLI
bin/jackal-mcp-ledger         optional MCP transparency/recall wrapper
assets/                       product visualizations
config/                       non-secret templates
tests/                        model, adapter, policy, and presentation gates
docs/                         operator and engineering documentation
scripts/check.sh              aggregate local gate
scripts/package-release.sh    deterministic source archive
```

## Design invariants

- The plugin ID is permanent and namespaced.
- The UI is not a mathematical engine.
- Returned status, refusal reason, subject, assumptions, consequence ceiling,
  and non-claims are not promoted or summarized away.
- Unknown shapes remain unknown.
- A failed read or parse clears old affirmative state.
- Graphs are visualization and remain explicitly estimated.
- Latest results are local recall.
- Verification expectations never come from the reviewed artifact.
- The dropdown's interaction contract remains backward compatible.
- The scrolling reading plane remains opaque and pixel-aligned.

## Run the gates

```sh
./scripts/check.sh
```

Fast checks do not start a full MCP runtime. To include the ledger's live
integration cases, run:

```sh
python3 -B tests/ledger.test.py
```

Live integration may take longer because JACKAL creates an isolated private
runtime snapshot.

## QML development

Develop only in a user-owned plugin tree. Do not edit `/usr/share/omarchy`.
Omarchy hot-reloads saved files under `~/.config/omarchy/plugins/`.

Validate after every manifest or entry-point change:

```sh
omarchy plugin validate .
./scripts/check.sh
```

The aggregate gate deliberately requires a Qt 6 `qmllint`; the unversioned
binary supplied by Qt 5 cannot parse Omarchy's Qt 6 QML. It builds an isolated
URI-shaped import view for Omarchy's `qs.*` modules and retains framework
diagnostics in `build/qmllint.log`. A passing result means the Qt 6 linter
accepted the sources, not that the framework-context diagnostics file is empty.

Inspect runtime logs:

```sh
qs log -p "$OMARCHY_PATH/shell" --tail 100
```

Exercise open, close, toggle, Escape, panel switching, mouse buttons, keyboard
shortcuts, scrolling, stale refresh, missing ledger, malformed ledger, missing
runtime, degraded probe, and verification refusal.

## Model development

`Model.js` is plain ECMAScript compatible with QML's `.pragma library`. Keep it
free of QML types and imports so Node can evaluate the exact source.

Every classification branch needs tests for malformed and missing inputs. Do
not add a default affirmative branch.

## Python adapter development

Python adapters must:

- use bounded input sizes;
- reject symlink or non-regular policy files where appropriate;
- use subprocess argument arrays rather than shell strings;
- apply timeouts to external calls;
- return named operator/router failures;
- preserve JACKAL payload fields verbatim;
- avoid writing bytecode into identity-pinned core plugin trees;
- avoid network access and privilege elevation;
- keep user-specific paths out of source.

## Test fixtures

Fixtures are captured evidence shapes, not evidence for a live installation.
Document provenance and intended mutation coverage. Never put real operator
authorization, credentials, private receipts, or ledger history in a fixture.

## Visual changes

The visual language is graphite, steel, white, and disciplined crimson. Avoid
green status semantics, scanlines, code rain, moving decorations behind text,
and effects that make glyph rasterization unstable while scrolling.

Update `preview.png` only from the actual running plugin. Verify it contains no
credentials, private artifact inputs, or unrelated personal information.

## Documentation review

Before release, ask whether a new reader can answer:

- What runs with user permissions?
- What is evidence and what is only recall?
- How is runtime integrity checked?
- How are expectations kept independent?
- What dependencies and network actions exist?
- How do install, update, rollback, and removal work?
- Which claims remain explicitly out of scope?

If the document cannot answer those from the repository alone, the release is
not ready.
