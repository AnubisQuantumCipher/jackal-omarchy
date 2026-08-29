# SPARK Platinum assurance boundary

## Claim

JACKAL Omarchy Edition contains a SPARK component whose contracts fully state
its allocated finite policy requirements and whose generated proof obligations
are discharged by GNATprove. That component is
`Jackal_Assurance_Policy` in `formal/src/`.

This is a component-scoped SPARK Platinum claim. It is not a claim that the
complete plugin, JACKAL runtime, operating system, compiler, JavaScript engine,
Qt/Quickshell stack, or hardware is Platinum, certified, or flight qualified.
The machine-readable source of truth is
[`assurance/requirements.json`](../assurance/requirements.json); its
whole-product status remains `not-established`.

## Allocated functional requirements

The proved component owns these requirements:

| Requirement | Functional obligation | Evidence |
|---|---|---|
| `JOP-DOCTOR-001` | Classify every finite doctor-policy input and make `Functional` equivalent to ready discovery, complete canonical probes, all probes passing, and matched identity. | SPARK equivalence postcondition, GNATprove report, and exhaustive shipped-Python vectors |
| `JOP-STATE-001` | Implement the complete priority-ordered display-state classifier for every value of its finite input type. | SPARK postcondition and GNATprove report |
| `JOP-STATE-002` | Return `Verified` exactly under the complete eligibility predicate. | SPARK equivalence postcondition and GNATprove report |
| `JOP-ASSURANCE-001` | Select no ceiling for an empty set and the canonical strongest declared mathematical class otherwise. | Membership, maximality, and tie-break postcondition |
| `JOP-CAP-001` | Apply a consequence cap exactly under the declared applicability and strength conditions. | SPARK equivalence postcondition |

The contracts are the functional specification for this component. They cover
the finite input domains, doctor eligibility, output relationships,
deterministic tie breaking, and termination. `formal/prove.sh` refuses a report
containing an unproved or justified check and rejects `pragma Assume` and
`pragma Annotate` in the formal source and vector driver.

## Refinement into the shipped plugin

Omarchy executes `Model.js` and the operator CLI, not Ada.
`JOP-BRIDGE-001` builds the Ada vector emitter and compares the shipped
JavaScript functions with the proved SPARK oracle over every finite state input,
every mathematical-status set, and every consequence-set/carries-axis
combination. `JOP-DOCTOR-001` separately compares every finite doctor-policy
input with the shipped Python verdict function. The JavaScript staleness
boundary and operator document assembly are locked separately.

This exhaustive differential test establishes conformance for the enumerated
finite abstraction. It is not a formal source-to-source refinement theorem.
JavaScript time arithmetic, JSON parsing, process execution, filesystem state,
QML rendering, and compositor behavior remain outside the SPARK proof boundary.

## Product assurance layers

| Layer | Method | Current claim |
|---|---|---|
| Pure policy kernel | Complete SPARK contracts and GNATprove | Component-scoped SPARK Platinum |
| JavaScript policy bridge | Exhaustive differential vectors | Tested conformance, not formal refinement |
| Operator diagnostics | Positive, negative, refusal, and live probes | Tested observations with explicit non-claims |
| QML presentation | Structural tests, QML lint, and live lifecycle checks | Tested presentation behavior |
| Release bytes | Clean-checkout deterministic packaging and byte comparison | Reproducible source archive when the gate passes |
| External JACKAL runtime | Identity-pinned discovery and delegated verification | Separate runtime assurance model |
| Platform and hardware | External dependencies | Not established by this repository |

## Reproduction

Install GNAT, GPRbuild, and GNATprove, then run:

```sh
JACKAL_REQUIRE_FORMAL=1 ./scripts/check.sh
./scripts/release-gate.sh
```

The first command checks bidirectional traceability, repository invariants,
unit and model behavior, the SPARK proof, exhaustive JavaScript conformance,
router behavior, shell syntax, and available Omarchy/QML validation. The release
gate adds the full ledger suite and independent clean-checkout reproduction.

The proof gate is fail-closed for release use. A development machine without
GNATprove may run non-formal checks only when `JACKAL_REQUIRE_FORMAL` is not set;
such a run is not evidence for the Platinum component claim.

## Assumptions and residual obligations

The SPARK proof relies on the semantics implemented by the selected GNAT and
GNATprove toolchain. It does not verify the compiler binary, prover binaries,
host kernel, CPU, or the correctness of the JavaScript engine. The GitHub
workflow pins third-party actions to immutable commits and selects explicit
GNAT, GPRbuild, and GNATprove crate versions, but its result remains a CI
observation; release reviewers should reproduce the gate in an independent
environment and retain tool versions and logs.

The remaining product-level closure work is explicit:

- replace differential testing with an accepted refinement argument or move
  the executed policy into a proved native boundary;
- specify and verify JSON/parser and process-adapter behavior;
- build evidence for QML interaction and rendering requirements;
- qualify or otherwise justify compiler, prover, platform, and hardware
  assumptions for the intended consequence level;
- connect this plugin assurance case to the separately versioned JACKAL runtime
  assurance case.

## Standards-facing interpretation

AdaCore describes Platinum as proof of full functional correctness when
contracts fully cover the requirements allocated to the proved code. NASA
software guidance requires bidirectional traceability between requirements and
their implementing and verifying artifacts. This repository follows those
ideas for its component claim; it does not claim organizational approval or
compliance certification.

Primary references:

- [AdaCore SPARK assurance levels](https://docs.adacore.com/spark2014-docs/html/ug/en/usage_scenarios.html)
- [AdaCore managing proof assumptions](https://docs.adacore.com/spark2014-docs/html/ug/en/source/how_to_use_gnatprove_in_a_team.html)
- [SPARK Reference Manual](https://docs.adacore.com/spark2014-docs/html/lrm/introduction.html)
- [NASA software bidirectional traceability](https://nodis3.gsfc.nasa.gov/displayDir.cfm?Internal_ID=N_PR_7150_002D_&page_name=Chapter3)
- [NASA software assurance and software safety](https://sma.nasa.gov/sma-disciplines/software-assurance-and-software-safety)
- [FAA AC 20-115D](https://www.faa.gov/regulations_policies/advisory_circulars/index.cfm/go/document.information/documentID/1032046)
