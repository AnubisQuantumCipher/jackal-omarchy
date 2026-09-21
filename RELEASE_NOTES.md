# JACKAL Omarchy Edition 3.0.1

3.0.1 is 3.0.0 with the full cockpit as the marketplace snapshot and a manifest description inside the marketplace's 500-byte cap (3.0.0 failed its compatibility validation on that cap alone).

This release rebuilds the plugin's three surfaces — bar pill, dropdown and
full-screen cockpit — on Omarchy's own UI kit and theme singletons. The private
palette is gone; the surfaces take every colour from the active theme and read
as first-party panels. The mathematical JACKAL runtime remains a separate,
pinned dependency with its own release epoch and assurance model, and the
display boundary is unchanged: assurance vocabulary verbatim, refusal identity
kept, recall labelled as recall, graph pixels never evidence.

## Highlights

- Theme-native everywhere: `Color.menu.*`, `Color.accent`, `Color.urgent`,
  `Style.font.*`, `Style.space` — no hex colour in any surface, enforced by
  `tests/presentation.test.py`.
- Bar pill with a live last-hour call count and an accent pulse on new ledger
  rows; a real Omarchy dropdown with activity instrument, latest answer, recent
  feed and one-key actions.
- Seven-deck cockpit: overview, ledger (filters, expandable rows), graph deck,
  probes, verify (with retained receipts and one-click re-verification),
  register, THOTH. `SUPER + SHIFT + J`, an app-launcher entry and
  `omarchy-shell khephri.jackal deck <name>` open it.
- Ledger analytics in `Model.js` (summary, buckets, histogram, leaderboard)
  under 42 new checks; every aggregate is a count of rows.
- One passive service for the cockpit, so two surfaces never run two doctors.

## Assurance boundary

- A count is a count of ledger rows. The bar's number, the activity instrument,
  the spectrum and the leaderboard are recall, and say so beside themselves.
- No number on any deck is typed in; the hardcoded surface totals are removed.
- The verification front door keeps the operator's expectations structurally
  separate from the artifact under review. A refusal there is a verdict.

## Verification

`./scripts/check.sh` — traceability, repository policy, operator CLI, ledger,
presentation, Model (177 checks), SPARK/JavaScript conformance, router, shell
syntax, `omarchy plugin validate`, and Qt 6 `qmllint` over every QML file.
