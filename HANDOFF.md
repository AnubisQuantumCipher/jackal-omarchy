# JACKAL Omarchy Edition handoff

This handoff is the working continuation document for the JACKAL + THOTH Omarchy
plugin repository. It is not an evidence certificate. Treat every status below
as "observed in this workspace" unless a cited tool or retained JACKAL receipt
can independently re-verify it.

## Current mission

Build and release a fully open-source Omarchy plugin edition of JACKAL that keeps
the existing JACKAL foundation intact while adding a professional, information-rich
desktop surface for:

- JACKAL evidence recall and function probes.
- Integrated THOTH measurement/provenance, not a separate entity.
- Graph preview and linked interactive STEM workspace presentation.
- CAS-style operator workflows: symbolic precision, matrices, regression, sensor
  acquisition, aerospace/space/engineering workflows, and HELLGATE-style bounded
  problem lanes.
- Marketplace-ready project structure, documentation, tests, preview assets, and
  release packaging.

The user explicitly wants the dropdown app from the Omarchy menu bar preserved.
Do not replace how it opens, closes, scrolls, or dispatches actions. Extend it
additively.

## Non-negotiable constraints

- Keep `manifest.json` id as `khephri.jackal`.
- Keep the visible plugin name as `JACKAL + THOTH`.
- Keep version `2.5.0` until a deliberate release bump is made.
- Keep the plugin as a bar widget with entry point `Panel.qml`.
- Keep `barWidget.category` as `Developer Tools`.
- Do not add a top-level `tags` field to `manifest.json`; tags belong in the
  marketplace submission issue.
- Do not represent THOTH as a separate product or service. THOTH is JACKAL's
  integrated measurement/provenance subsystem.
- Carry JACKAL evidence classes exactly: `exact`, `bounded`, `formal-bounded`,
  `checked`, `estimated`, `model-based`, `exact-given`, or the specific class
  returned by the tool.
- Do not silently upgrade assurance. HELLGATE remains `bounded` unless a formal
  checker actually returns `formal-bounded`.
- Graph pixels are visualization only. Never call the graph preview proof,
  verification, or mathematical evidence.
- No result may be called certified unless an explicit verification artifact or
  accepted checker result supports that label.
- Do not claim NASA, SpaceX, Omarchy, or another external organization has
  endorsed the project. The docs should frame this as pilot-ready engineering
  infrastructure, not flight-qualified software.
- Do not use, store, commit, or echo the GitHub token that appeared in the chat.
  It should be treated as compromised and revoked by the owner.

## Workspace map

Primary repo:

```text
<workspace>/Projects/jackal-omarchy
```

Original JACKAL repo, preserved and not merged into this edition:

```text
<workspace>/Projects/jackal
```

Live installed Omarchy plugin:

```text
$HOME/.config/omarchy/plugins/khephri.jackal
```

Pre-upgrade backup:

```text
$HOME/.local/state/jackal-omarchy/backups/pre-2.5.0.x3mWVX
```

JACKAL result recall files:

```text
$HOME/.local/state/jackal/results.jsonl
$HOME/.local/state/jackal/receipts/
```

Disposable, unsealed Codex Security scan workspace that was canceled at the
user's request:

```text
/tmp/codex-security-scans/jackal-omarchy/standard.7x2XRu
```

Do not cite that canceled scan as complete.

## Git and publication state

Observed local state:

- Repository branch is `main`.
- The initial local release commit exists.
- The source tree was staged and committed locally for `2.5.0`.
- GitHub remote `origin` is configured for the public repository.
- GitHub CLI authentication was completed through the browser/device flow.

Public repository:

```text
https://github.com/AnubisQuantumCipher/jackal-omarchy.git
```

Publication note:

- The available OAuth token did not include the `workflow` scope. GitHub
  therefore rejected commits containing `.github/workflows/*`. For this publish,
  GitHub Actions workflow files were removed so the public repository, tag,
  release archive, and marketplace submission can proceed without requesting
  broader credential scope.
- Do not use the token from the chat.

## Implemented source tree

Observed repository files include:

```text
.github/ISSUE_TEMPLATE/bug_report.yml
.github/ISSUE_TEMPLATE/config.yml
.github/ISSUE_TEMPLATE/feature_request.yml
.github/PULL_REQUEST_TEMPLATE.md
.gitignore
CHANGELOG.md
CODE_OF_CONDUCT.md
CONTRIBUTING.md
HANDOFF.md
LICENSE
Model.js
NOTICE.md
Panel.qml
README.md
RELEASE_NOTES.md
SECURITY.md
Service.qml
VERSION
assets/jackal-linked-evidence-workspace.png
assets/jackal-thoth-hellgate-graph.png
bin/jackal-mcp-ledger
bin/omarchy-jackal
config/config.example.json
config/jackal-expectations.example.json
docs/ARCHITECTURE.md
docs/ASSURANCE_MODEL.md
docs/DEPENDENCIES.md
docs/DEVELOPMENT.md
docs/ENGINEERING_PILOT.md
docs/INSTALLATION.md
docs/OPERATIONS.md
docs/RELEASE_PROCESS.md
docs/THREAT_MODEL.md
manifest.json
preview.png
scripts/check.sh
scripts/package-release.sh
tests/fixtures/capability_inventory_v173.json
tests/fixtures/certified_pi_enclosure.json
tests/fixtures/maturity_v1.7.3.txt
tests/ledger.test.py
tests/model.test.mjs
tests/operator_cli.test.py
tests/presentation.test.py
tests/repository.test.py
tests/router.test.py
verify_artifact.py
```

There was also an ignored Python cache file under `bin/__pycache__/` in an
earlier status snapshot. Remove generated caches before committing if still
present.

## Product state

The plugin is a real Omarchy bar-widget surface, not a static mock:

- `Panel.qml` owns the dropdown presentation.
- `Service.qml` owns shell/process integration, result recall, inventory reads,
  artifact verification dispatch, and copy operations.
- `Model.js` owns display modeling, parsing, filtering, and state shaping.
- `bin/jackal-mcp-ledger` is the MCP/front-door wrapper that records JACKAL
  calls into the shared ledger.
- `bin/omarchy-jackal` provides the operator CLI/doctor path.
- `verify_artifact.py` provides artifact verification routing against runtime
  and operator-owned expectations.

The dropdown was upgraded in the requested direction:

- Serious graphite/steel/white/crimson visual system.
- No green in the final palette.
- Professional, information-dense layout.
- Latest results view.
- Evidence register.
- Function probe/status cards.
- Runtime verification affordance.
- Graph preview for HELLGATE-style input.
- Linked workspace presentation for graph, matrix, regression, sensor,
  aerospace, and evidence lanes.
- Scroll-jitter fix was validated by settled frame comparison in the live shell
  capture workflow.

## Live install status

The live installed manifest matches the source manifest for id/name/version:

```text
id: khephri.jackal
name: JACKAL + THOTH
version: 2.5.0
```

Latest local sync:

The source tree was synced into the live installed plugin directory after a
fresh backup under:

```text
$HOME/.local/state/jackal-omarchy/backups/final-sync-2.5.0.*
```

The installed plugin was compared against the source tree, excluding `.git`,
`build`, and `dist`, and no differences were reported.

The synced file uses absolute command paths for:

```text
/usr/bin/python3
/usr/bin/cat
/usr/bin/wl-copy
```

Observed live checks after sync:

```text
Service.qml cmp source/install: 0
omarchy plugin validate: exit 0
installed doctor: FUNCTIONAL
installed runtime verify: PASS
omarchy-shell shell rescanPlugins: exit 0
```

## Visual evidence already observed

Observed preview artifact:

```text
preview.png
```

Observed preview properties from the earlier capture:

```text
dimensions: 694x1154
sha256: d9f4d3a911cf4f5f8992a9954c4c52511e3d2b3c03ca4814402483787159d4ef
```

Observed live acceptance from earlier session work:

- Omarchy plugin validator passed.
- Installed doctor reported `FUNCTIONAL`.
- Runtime verifier reported `PASS`.
- IPC status reported `FUNCTIONAL`.
- Escape closed the panel.
- Reopen reset scroll.
- IPC verify dispatch worked.
- No JACKAL QML errors were observed in the shell log; unrelated BlueZ,
  portal, and omadock warnings were present.
- Settled scrolled-frame comparisons were pixel-identical in the ImageMagick
  check.

These observations predate the latest source sync. The command-level live
checks after sync passed; repeat a visual capture if a release gate requires
fresh screenshot evidence.

## JACKAL and THOTH sampling already performed

Representative JACKAL/THOTH behavior was sampled through the MCP/ledger route.
Preserve the evidence labels exactly:

- Arithmetic/CAS sample: `exact`.
- Matrix sample: `exact`, informational only.
- Regression sample: `model-based`.
- Sensor sample: `exact-given`, with nested standard deviation lane
  `formal-bounded`.
- Aerospace sample: `model-based`, advisory.
- HELLGATE sample: `bounded`, not formal.
- Graph sample: `estimated`, informational.
- Linked workspace sample: `checked`, informational.

THOTH tools sampled:

- convert: `exact`.
- rate apply: `exact-given`.
- percent: `exact`.
- date delta: `exact-given`.
- stat: `exact`, with nested `formal-bounded`.
- compare: `exact`.
- scan: `checked`.

Graph expression sample observed:

```text
parsed: x^6-5*x^4+4*x^2
interval: [-3,3]
samples: 129
status: estimated
```

The docs describe the current observed package composition as:

```text
41 sealed runtime tools
7 THOTH tools
3 advanced tools
7 STEM tools
```

Those are release declarations and inventory observations, not universal
execution evidence for every possible input.

## Test state

Observed aggregate check after this handoff was added:

```text
./scripts/check.sh
```

It passed these lanes:

- repository policy tests.
- operator CLI tests.
- presentation tests.
- ledger fast tests.
- Model.js tests.
- router tests.
- Bash syntax checks.
- Omarchy plugin validator.
- Qt6 `qmllint`.

Observed aggregate result:

```text
JACKAL_OMARCHY_CHECK_PASS
```

Additional observed test:

```text
python3 -B tests/ledger.test.py
```

Observed result:

```text
66 checks passed
```

Known tool availability caveat:

- `shellcheck` was unavailable.
- `yamllint` was unavailable.

Do not claim those two tools passed unless they are installed and actually run.

The latest source changes after the earlier live acceptance include the
absolute-command-path hardening in `Service.qml` and this handoff. The source
test suite has passed after these changes. The live installed plugin has been
synced and command-level live checks passed after sync.

## Release packaging state

`scripts/package-release.sh` was run after the initial local commit. It requires:

- semver `VERSION`.
- `manifest.json` version matching `VERSION`.
- clean git tree.
- passing tests.
- no pre-existing archive/digest for the same version.
- a committed source state because packaging uses `git archive`.

Observed packaged outputs:

```text
dist/jackal-omarchy-v2.5.0.tar.gz
dist/jackal-omarchy-v2.5.0.tar.gz.sha256
```

Read the current archive digest from the `.sha256` file after packaging.

Only run the GitHub commands after a fresh safe authentication flow is in place.

## Marketplace state

Marketplace researched earlier:

```text
https://omarchyplugins.com/
https://omarchyplugins.com/publish.html
https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md
https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SECURITY.md
```

Marketplace intent:

- root public repo.
- valid root `manifest.json`.
- README and license present.
- safe install/remove behavior.
- valid `preview.png`.
- category: `Developer Tools`.
- issue tags to request: `ai`, `bar`, `quickshell`.

Marketplace issue creation is an external write. The next session must present
the exact issue title/body to the user and obtain explicit approval before
opening the submission issue.

Draft marketplace issue title:

```text
Add plugin: JACKAL + THOTH
```

Draft marketplace issue body:

```markdown
Repository: https://github.com/AnubisQuantumCipher/jackal-omarchy

Manifest id: khephri.jackal
Plugin name: JACKAL + THOTH
Category: Developer Tools
Requested tags: ai, bar, quickshell

Summary:
JACKAL + THOTH is an open-source Omarchy bar widget for evidence-aware STEM
workflows. It surfaces recent JACKAL results, integrated THOTH measurement and
provenance, runtime verification routing, function probes, evidence register
views, and professional graph/linked workspace previews while preserving the
JACKAL assurance labels exactly.

Notes:
- THOTH is integrated into JACKAL; it is not submitted as a separate plugin.
- Graph previews are informational visualization, not proof artifacts.
- The plugin does not claim external endorsement or flight qualification.
```

## Credential incident

The chat contained a GitHub personal access token. Treat it as compromised.

Required owner action:

- Revoke the exposed token in GitHub.
- Authenticate using a fresh browser/device flow such as `gh auth login`.
- Do not paste another long-lived token into chat.

Do not put the old token in any command, config file, git remote URL, commit,
release artifact, issue, or documentation.

## Canceled security scan

A Codex Security standard scan was started, then the user explicitly said they
did not need a scan. The scan was stopped and must not be resumed or described
as complete unless the user asks for that work again.

Unsealed preliminary hardening observations from that abandoned pass may still
be useful as ordinary engineering tasks, but they are not validated findings:

- The doctor path probes runtime behavior before the separate full verify
  command. Consider tightening integrity-ordering in a later hardening pass.
- QML `Text` controls that display ledger/router strings should prefer
  `textFormat: Text.PlainText` where possible to reduce styled-text spoofing.
- Clipboard, file, and front-door paths have size checks after some buffering;
  consider enforcing pre-buffer caps.
- Ledger and receipt directories/files rely on umask; consider explicit
  directory/file permissions.
- MCP observation buffering should consider a pre-newline cap.
- The router path still used bare `wl-paste` when this note was prepared;
  check and use absolute paths if appropriate.

If the user continues to reject security scanning, handle these only as normal
hardening items and do not call them security findings.

## Recommended remaining order

1. Rebuild release packaging if the commit is amended after this note.
2. Add remote and push after safe GitHub authentication.
3. Prepare the marketplace submission issue and get explicit user approval.
4. Create the marketplace issue only after approval.

Optional fresh visual release gate:

- No green.
- Serious graphite/steel/crimson look.
- No text shaking during scroll.
- Latest results section works.
- Graph preview renders.
- Runtime verify dispatch works.
- Escape closes the panel.
- Reopen resets scroll.

## Definition of done for this release

This release is done only when all of these are true:

- Source tests pass in the repo.
- Live installed plugin is synced from the exact source state being released.
- Visual dropdown acceptance is repeated after sync.
- No generated caches are staged.
- `git status --short` is clean after commit.
- Remote GitHub repo exists and `main` is pushed.
- Release artifact is generated from the committed source state.
- The release notes match the actual release artifact.
- Marketplace issue body has explicit user approval.
- No compromised credential appears anywhere in the repo or Git metadata.

## What not to do

- Do not edit the original `<workspace>/Projects/jackal` repo unless the user
  explicitly asks for core JACKAL changes.
- Do not reset or overwrite user work.
- Do not change the dropdown activation model.
- Do not split THOTH into a separate plugin.
- Do not overclaim formal verification or certification.
- Do not submit the marketplace issue without showing the exact body first.
- Do not resume the canceled security scan unless the user asks.
- Do not use the exposed GitHub token.
