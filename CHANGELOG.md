# Changelog

All notable changes are recorded here. The project follows Semantic Versioning
for the Omarchy integration. JACKAL runtime epochs are versioned independently.

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
