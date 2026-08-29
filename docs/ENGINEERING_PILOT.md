# Engineering Pilot Guide

## Positioning

JACKAL Omarchy Edition can support an engineering pilot in which an AI agent's
quantitative work is routed through a deterministic evidence kernel and its
assurance boundary is made visible to operators. It is not flight software, a
qualified development tool, a certified analysis package, or an approved NASA
or SpaceX workflow component.

The right near-term objective is not a claim of mission readiness. It is an
externally reviewable pilot that can produce evidence about whether the approach
reduces untraceable arithmetic, silent fallback, and status laundering.

## Candidate pilot scope

Suitable initial work is reversible and independently reviewable:

- exact unit-aware arithmetic and rational transformations;
- checker-admitted range and integration demonstrations;
- evidence-aware graph and linked-view exploration;
- engineering calculations whose source inputs are already approved;
- receipt replay and tamper-refusal exercises;
- offline comparison against an existing analysis workflow;
- operator studies on refusal comprehension and evidence labeling.

Do not begin with autonomous command, flight control, hazard closure, structural
certification, trajectory authorization, or any workflow where an incorrect
result can directly produce an unsafe act.

## Pilot architecture

1. An existing approved workflow remains authoritative.
2. JACKAL runs in shadow mode on the same operator-approved inputs.
3. The Omarchy panel exposes runtime identity, fresh probes, result classes,
   refusal reasons, and retained evidence links.
4. Outputs are compared by an independent reviewer.
5. Disagreements are classified as input, model, implementation, integration,
   numerical, policy, or human-interface issues.
6. No JACKAL result automatically changes an operational system.

## Required pilot artifacts

- system context and data-flow diagram;
- scoped requirements with bidirectional traceability;
- input provenance and unit policy;
- configuration and exact commit inventory;
- threat model and hazard analysis;
- test plan with positive, negative, mutation, boundary, and recovery cases;
- independent verification record;
- discrepancy log and resolution evidence;
- operator training material;
- rollback and incident-response procedure;
- explicit limitations and non-claims;
- final pilot report with reproducible commands and retained artifacts.

## Acceptance measures

Measures should be declared before collecting results. Examples include:

- fraction of quantitative answers carrying a recognized assurance class;
- fraction of refusals preserved without weaker fallback;
- traceability from displayed result to re-verifiable artifact;
- discrepancy discovery rate relative to the baseline workflow;
- operator identification of estimate versus enclosure versus exact result;
- reproducibility on a separately prepared machine;
- update and rollback recovery time;
- number and severity of unresolved safety/security findings.

These measures describe a pilot. They do not by themselves establish tool
qualification or suitability for a mission.

## Qualification gaps

Before consequential adoption, an organization would normally need to address:

- authoritative requirements and change control;
- formal mapping from requirements to implementation and tests;
- independent verification and validation;
- source-to-native refinement or an approved tool-qualification argument;
- compiler, interpreter, checker, and operating-environment qualification;
- numerical method validation against independent implementations;
- cybersecurity assessment and software supply-chain controls;
- human factors, accessibility, alarm semantics, and workload evaluation;
- configuration identification, release signing, provenance, and retention;
- fault containment, degraded modes, recovery, and operational monitoring;
- legal, export-control, licensing, and data-handling review;
- mission-specific hazard analysis and approval authority.

SPARK or Lean proofs can discharge narrowly stated software properties. They do
not automatically prove model validity, measurement truth, integration
correctness, physical suitability, or system safety.

## Grant-ready evidence package

A credible proposal should lead with a bounded research question and evidence
plan rather than claims that incumbent engineering systems are obsolete. A
strong package includes:

- the problem: AI arithmetic and evidence provenance are unreliable without a
  deterministic front door;
- the technical novelty: typed epistemic classes, refusal-first routing,
  content-addressed artifacts, independent replay, and operator-visible
  consequence ceilings;
- the work plan: close specified formal, numerical, security, and usability
  gaps;
- milestones tied to reproducible artifacts;
- independent evaluators and comparison baselines;
- open-source deliverables and public benchmark corpora where permitted;
- transition criteria for a limited engineering pilot;
- an honest residual-risk and non-claim register.

No document can guarantee funding, procurement, qualification, or endorsement.
Credibility comes from making those boundaries explicit and producing evidence
reviewers can independently reproduce.

## Exit criteria

A pilot should stop or remain shadow-only when:

- a required status is promoted or silently downgraded;
- a refusal is routinely bypassed;
- inputs cannot be traced to an approved source;
- independent reproduction fails;
- critical security or integrity findings remain unresolved;
- operators misinterpret estimates or graphs as proof;
- update provenance cannot be established;
- organizational safety authority has not approved the intended consequence.
