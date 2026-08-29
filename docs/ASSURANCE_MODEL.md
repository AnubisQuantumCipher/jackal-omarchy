# Assurance Model

## The display contract

JACKAL answers two independent questions:

1. How was this result established?
2. What is the maximum consequence permitted from it?

The Omarchy surface displays both without collapsing them into a score, color
gradient, confidence percentage, or generic success badge.

## Mathematical status classes

### `exact`

Exact integer or rational computation in the admitted grammar. It is outside
the Lean certificate chain. Exactness of arithmetic does not establish that an
input measurement, model, requirement, or program is correct.

### `formal-bounded`

A pinned checker accepted a certificate for a declared expression fragment and
request. It applies only to that fragment, request binding, checker identity,
and release policy. It is not a synonym for arbitrary formal verification.

### `bounded`

A closed interval returned under stated numerical and rounding assumptions. It
must not be displayed as `formal-bounded` merely because the interval is narrow.

### `checked`

A defined check or comparison was performed. A sampled differential check, for
example, is not an identity proof.

### `estimated`

A numerical estimate with an error estimate or convergence diagnostic that is
not a mathematical enclosure. Graph y-values use this class.

### `model-based`

A result conditional on a caller-declared model. Exact computation inside a
model does not validate the model.

### `refused`

The requested lane did not admit the syntax, domain, policy, identity, resource
budget, or evidence. Refusal is the result; the UI does not reroute the request
to a weaker lane.

## Other evidence classes

JACKAL also declares classes such as `structural-exact`,
`verified-program-evidence`, and `verified-program-receipt`. These are not
silently inserted into the mathematical ranking. Their meanings and residuals
remain specific to the originating tool.

## Consequence ceilings

| Ceiling | Meaning |
|---|---|
| `informational` | May inform understanding; cannot authorize consequential action by itself |
| `advisory` | May support advice under independent review |
| `decision-boundary` | May participate in the declared numeric decision boundary |
| `safety-critical` | Highest declared ceiling; still does not replace system qualification or operational authority |

A ceiling is an upper bound, not a grant. `exact` arithmetic with an
`informational` ceiling remains informational. A `safety-critical` ceiling does
not turn estimated evidence into a proof.

## Declaration versus observation

The generated capability inventory declares what a release says a tool can
return. A doctor probe observes what selected tools returned in one invocation.
The panel keeps those accounts separate:

- **declared surface** — read from `capability_inventory_v1.json`;
- **session function** — populated only from tools actually executed now;
- **runtime integrity** — populated only when the core provisioner accepts;
- **latest results** — local recall from prior MCP traffic.

No one account substitutes for another.

## Ledger boundary

`results.jsonl` is a convenience file written by the proxy. Any process running
as the user may edit it. Therefore:

- a ledger status is displayed as copied, not independently believed;
- a ledger answer is labeled recall;
- a digest is not evidence of the referenced artifact's validity;
- a retained receipt becomes evidence only after a JACKAL verification front
  door accepts it against operator-owned expectations.

## Verification authorization

A verification request must be bound to values the operator authorized before
reviewing the artifact. The router reads those values from a separate file. It
does not discover expected values from the artifact.

This prevents the circular check in which an artifact says what answer should
be expected and is then declared valid because it matches itself.

## HELLGATE boundary

The HELLGATE checker returns `status=bounded`, `formal=false`. Trial-function
diagnostics are labeled as trial quantities. Any transfer to a true ground-state
quantity states the theorem and assumptions on which that transfer depends.

The UI may show a bounded eigenvalue enclosure, trial virial residual, or graph
preview. It does not establish the remaining Bogoliubov spectrum, nonlinear
sensitivity, tunneling splitting, or every ground-state moment unless a future
JACKAL result explicitly supplies those claims and their evidence.

## Visual semantics

Graphite, steel, white, and crimson form the interface palette. Color is not a
mathematical ordering. Text labels and explicit status vocabulary carry the
meaning. The graph is marked `status=estimated visualization` and `pixels are
not proof` at the point of use.

## Required non-claims

The surface must not suppress these classes of residual:

- finite campaigns do not establish universal correctness;
- source-to-native refinement remains separate unless explicitly proved;
- input truth and model validity are not supplied by arithmetic;
- operating system, compiler, hardware, and supply chain are outside a
  mathematical receipt unless separately covered;
- marketplace approval is listing approval, not a security audit or
  engineering qualification.
