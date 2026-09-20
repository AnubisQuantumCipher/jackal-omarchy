# JACKAL Omarchy Edition 2.7.1

This release turns the bar dropdown into a full-screen mission-control cockpit
and makes its graph deck an instrument. The deck evaluates expression, range,
and preset sweeps through the installed runtime's own `jackal-native worksheet`
lane in bounded batches and renders them on an instrument canvas; a statement
the evaluator refuses becomes a break in the curve, never an invented value,
and the render remains `status=estimated` visualization. Everything 2.6.3
proved and reproduced is retained unchanged: the component-scoped SPARK
Platinum assurance-policy kernel, exhaustive JavaScript conformance,
deterministic clean-checkout release reproduction, and the pinned public
assurance automation. The mathematical JACKAL runtime remains a separate,
pinned dependency with its own release epoch and assurance model.

## Highlights

- Mission-control dropdown: the panel claims the entire available screen
  plane below the bar and lays its accounts out as a three-column cockpit —
  SYSTEMS (doctor, identity, surface totals, agent surface, digests),
  OPERATIONS (live graph deck, clipboard verification, evidence register),
  and TELEMETRY (latest ledger answers, session function probes) — under a
  pinned command strip and the never-scrolling laws/non-claim footer.
- Live graph deck evaluated by the installed runtime's `jackal-native
  worksheet` lane in bounded batches; refused statements break the curve
  rather than being interpolated, and pixels remain not proof. The approved
  HELLGATE reference render stays as the deck's empty-state placeholder.
- Instrument-grade plot: a left gutter sized to its own labels, 1/2/5-decade
  tick gridlines with step-scaled precision, refused runs shaded as bands
  that own exactly the refused samples, dots where the pen lifted, observed
  max and min marked where they sit (evaluator samples, never window
  padding), and a hover crosshair that reads out the nearest evaluator
  sample by number — it never interpolates, because between samples there is
  no claim.
- The pure tick, band, extreme, and hover logic lives in Model.js under 60+
  new checks, which immediately caught and removed a "-0.0" tick label.
- Surface totals state the unified 74-tool Codex surface: sealed 41, THOTH 7,
  advanced 3, STEM 7, certified number theory 10, engineering 6.
- `g` focuses the graph expression field; the telemetry feed shows up to ten
  ledger answers.
- Retained from 2.6.3: catalog-safe migration from a manually copied plugin,
  fail-closed doctor behavior, the transparent MCP ledger with retained formal
  receipts, and the verification router that keeps operator expectations
  structurally separate from the artifact under review.

## Compatibility

- Omarchy Quattro shell plugin interface.
- Plugin ID: `khephri.jackal`.
- JACKAL runtime: discovered dynamically through the installed Codex plugin and
  runtime locator.
- Python 3.10 or newer.

## Verification boundary

The release proves the requirements allocated to `Jackal_Assurance_Policy` and
tests presentation, parsing, routing, refusal behavior, operator diagnostics,
ledger transparency, concurrency, outward rendering, repository policy,
release reproduction, and live Omarchy validation on the development host. The
complete mixed-language plugin is not claimed as Platinum. These checks do not
establish universal correctness, security certification, mathematical
soundness of every JACKAL lane, flight qualification, or organizational
endorsement.

## Install

```sh
omarchy plugin add https://github.com/AnubisQuantumCipher/jackal-omarchy.git --enable
```

Review the source and exact release commit before installation. Omarchy plugins
run unsandboxed as the current user.

## Remove

```sh
omarchy plugin remove khephri.jackal
```

Removal does not delete JACKAL runtimes, operator expectations, ledger rows, or
retained receipts.
