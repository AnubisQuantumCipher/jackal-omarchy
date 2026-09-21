# Changelog

All notable changes are recorded here. The project follows Semantic Versioning
for the Omarchy integration. JACKAL runtime epochs are versioned independently.

## 3.0.0 — 2026-09-20

### Changed

- Rebuilt every surface on Omarchy's own UI kit and theme singletons. The
  private graphite-and-crimson palette is gone; every colour, size and spacing
  now comes from the active theme (`Color.menu.*`, `Color.accent`,
  `Color.urgent`, `Style.font.*`, `Style.space`), so the plugin renders native
  under any Omarchy theme. State colours keep their rule and their lack of a
  middle value: established → text colour, refusal or downgrade → urgent, not
  established → dimmed. Accent is chrome and the activity instrument only.
- The bar slot is a pill again — one glyph for session function — and now
  carries the number of kernel calls in the last hour beside it. A count of
  ledger rows is recall and states no answer; it can be switched off with
  `barShowActivity`. A new ledger row lights a brief accent underline.
- Left click opens a real Omarchy dropdown (`KeyboardPanel` + `PanelHero` +
  `PanelKeyCatcher`): live activity instrument, latest answer, recent feed,
  one-key actions, single-cursor j/k/h/l navigation and Tab to the neighbouring
  panel. Middle click opens the cockpit; right click probes.
- The cockpit is a centred, scrim-backed mission-control card with seven decks
  (1–7, Tab): OVERVIEW with stat tiles, a bucketed activity timeline, a status
  spectrum, the latest answers, session function, the sealed runtime, a tool
  leaderboard and the verify lane; LEDGER with filters and rows that expand to
  the returned fields, full arguments and non-claims; GRAPH; PROBES; VERIFY
  with the retained receipts listed for one-click re-verification; REGISTER
  with each family's backing sentence; THOTH with every identity read from the
  runtime.
- The cockpit's service is passive: it probes on open and on demand, so two
  surfaces no longer run two doctors every interval. The runtime tree check runs
  once per cockpit session so the provisioner is named without a click.

### Added

- `Model.js` ledger analytics: `parseLedger`, `ledgerSummary`,
  `activityBuckets`, `statusHistogram`, `toolLeaderboard`, `feedRows` and
  formatting helpers, with 42 new checks. Every aggregate is a count of rows;
  none re-derives a status.
- Shared instrument components (`Jk*.qml`): result row, timeline, spectrum,
  chip, stat tile, key/value line, leaderboard row, section title.
- Operator settings `activityWindowHours`, `feedLimit`, `barShowActivity`.
- IPC routes `deck <name>` and `verify`; a `.desktop` launcher with deck
  actions; the `SUPER + SHIFT + J` binding.

### Removed

- The typed-in "74 tools / STEM / number theory / engineering" tiles. The THOTH
  deck now shows the declared tool count from the installed inventory and the
  distinct tools observed in the ledger, and nothing that was not read.

## 2.7.1 — 2026-08-29

### Improved

- Instrument-grade graph deck. The plot now sizes a left gutter to its own
  labels and draws 1/2/5-decade tick gridlines with step-scaled precision, so
  every line the eye crosses names a short readable number instead of the old
  ten-digit corner text. Refused runs are shaded bands that own exactly the
  refused samples; segment endpoints where the pen lifted carry dots; the
  observed max and min are marked where they sit (evaluator samples, never
  window padding); the trace gets a soft under-glow; and a hover crosshair
  reads out the nearest evaluator sample by number — it never interpolates,
  because between samples there is no claim. The pure tick/band/extreme/hover
  logic lives in Model.js under 60+ new checks, which immediately caught and
  killed a "-0.0" tick label.

## 2.7.0 — 2026-08-29

### Added

- Mission-control dropdown: the panel now claims the entire available screen
  plane below the bar and lays its accounts out as a three-column cockpit —
  SYSTEMS (doctor, identity, surface totals, agent surface, digests),
  OPERATIONS (live graph deck, clipboard verification, evidence register),
  and TELEMETRY (latest ledger answers, session function probes) — under a
  pinned command strip and the never-scrolling laws/non-claim footer.
- Live graph deck: expression, range, and preset sweeps are evaluated by the
  installed runtime's own `jackal-native worksheet` lane in bounded batches
  and rendered on an instrument canvas. A statement the evaluator refuses
  becomes a break in the curve, never an invented value; the render remains
  `status=estimated` visualization and pixels remain not proof. The approved
  HELLGATE reference render stays as the deck's empty-state placeholder.
- Surface totals now state the unified 74-tool Codex surface: sealed 41,
  THOTH 7, advanced 3, STEM 7, certified number theory 10, engineering 6.
- `g` focuses the graph expression field; the telemetry feed shows up to ten
  ledger answers.

## 2.6.3 — 2026-08-29

### Corrected

- Manual-copy migration now stores operator backups outside Omarchy's plugin
  catalog. A visible manifest-bearing backup under the catalog can retain the
  permanent plugin ID and block the replacement Git clone.
- Repository policy tests reject a regression to the conflicting backup path
  and require the catalog-safe migration procedure and warning.

## 2.6.2 — 2026-08-29

### Corrected

- Release reproduction no longer fetches or executes any remote source. It
  materializes the validated commit through local `git archive`, creates two
  independent repositories with deterministic commit metadata, and refuses
  unless both local tree identities equal the source commit tree before build.
- Repository policy tests now reject clone, fetch, remote, and shared-worktree
  reproduction paths.

## 2.6.1 — 2026-08-29

### Corrected

- The independent release-reproduction harness no longer performs an implicit
  checkout while cloning. It requires a full lowercase commit identity,
  fetches only that exact object into each empty checkout, detaches at it, and
  verifies `HEAD` again before executing either build.
- Repository policy tests now refuse any regression to a movable-ref or
  implicitly checked-out release-reproduction path.

## 2.6.0 — 2026-08-28

### Added

- Requirements-complete SPARK policy kernel with component-scoped Platinum
  contracts for display-state classification, assurance ceilings, and
  consequence caps.
- Exhaustive differential conformance vectors between the proved SPARK policy
  and the shipped JavaScript model.
- Machine-readable bidirectional requirements, implementation, verification,
  residual-risk, and product-boundary baseline.
- Fail-closed formal, traceability, reproducibility, and release gates.
- Pinned GitHub assurance automation and a standards-facing Platinum boundary
  document.

### Corrected

- Release archives no longer carry nondeterministic POSIX PAX access/change
  timestamps; independent clean checkouts now produce byte-identical archives.
- The operator doctor no longer reports `FUNCTIONAL` when a canonical probe is
  absent from the runtime inventory.
- Documentation no longer implies that a component proof establishes
  whole-plugin, platform, hardware, certification, or flight-readiness claims.
- Hosted proof dependencies install under the runner-temporary directory, so
  repository-integrity checks inspect only the reviewed release tree.

## 2.5.0 — 2026-08-28

### Added

- First standalone, fully open-source JACKAL Omarchy Edition repository.
- Repository-bundled operator CLI with dynamic runtime discovery.
- Explicit separation between installed presence, pinned integrity verification,
  and function observed through fresh probes.
- Optional transparent MCP ledger wrapper with structured HELLGATE recall.
- Retained receipt and claim-bundle routing against operator-owned expectations.
- Marketplace preview captured from the running dropdown.
- Complete architecture, assurance, installation, operations, dependency,
  threat-model, engineering-pilot, development, and release documentation.
- Release packaging, contribution templates, and security policy.

### Changed

- The dropdown now executes its bundled operator CLI instead of relying on an
  unexplained executable on the user's `PATH`.
- Runtime paths come from the validated doctor payload, with a compatibility
  fallback for a payload already in memory during hot reload.
- The operator CLI discovers the installed JACKAL Codex plugin rather than
  assuming a fixed source checkout or runtime epoch.

### Preserved

- Plugin ID `khephri.jackal` and all dropdown mouse and keyboard behavior.
- Graph assurance labels, refusal handling, evidence register, latest-result
  recall boundary, stable scrolling plane, and graphite/crimson visual system.
- THOTH as an integrated JACKAL subsystem rather than a separate authority.

### Security

- No credentials, operator authorization, runtime receipts, or local ledger
  contents are shipped.
- Runtime deletion remains unavailable from the dropdown and requires an
  explicit CLI command and confirmation flag.
- Core runtime integrity verification refuses unless the identity-pinned JACKAL
  provisioner is discoverable and accepts the installed tree.
