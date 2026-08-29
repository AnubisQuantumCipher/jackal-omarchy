# Assurance and SPARK Platinum boundary

The machine-readable baseline is [requirements.json](requirements.json). Every
requirement is a uniquely identified shall-statement with implementation,
verification, status, and residual-risk links. `scripts/check-traceability.py`
checks both directions: every linked artifact exists and every artifact carries
the requirement identifier it claims to implement or verify.

AdaCore defines SPARK Platinum as full functional correctness when contracts
fully cover the allocated functional requirements. The current Platinum claim
is deliberately component-scoped to `Jackal_Assurance_Policy`: GNATprove checks
the complete finite-domain contracts, absence of targeted run-time errors, and
termination. The proof gate refuses any unproved check, justified check,
`pragma Assume`, or `pragma Annotate`.

The shipped state policy remains JavaScript because Omarchy loads
QML/JavaScript, and the operator doctor remains Python. Exhaustive differential
gates compare both finite policy surfaces with vectors from the proved SPARK
component. This is strong conformance evidence, but it is not a formal
source-to-source refinement proof and therefore does not make the complete
plugin Platinum.

The product-level status remains `not-established` until the QML, JavaScript,
Python, shell, process, parser, operating-system, compiler, and external JACKAL
runtime boundaries are either moved into proved components or discharged by an
accepted compositional assurance case.

Primary references:

- [AdaCore SPARK assurance levels](https://docs.adacore.com/spark2014-docs/html/ug/en/usage_scenarios.html)
- [AdaCore managing proof assumptions](https://docs.adacore.com/spark2014-docs/html/ug/en/source/how_to_use_gnatprove_in_a_team.html)
- [NASA software bidirectional traceability](https://nodis3.gsfc.nasa.gov/displayDir.cfm?Internal_ID=N_PR_7150_002D_&page_name=Chapter3)
- [NASA software assurance and software safety](https://sma.nasa.gov/sma-disciplines/software-assurance-and-software-safety)
