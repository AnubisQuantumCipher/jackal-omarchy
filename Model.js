.pragma library

// Pure classification and formatting for the JACKAL widget.
//
// JACKAL's governing idea is that an answer is worth exactly what stands behind
// it, and that two independent things must be stated about every result:
//
//   ASSURANCE   how well the fact is established
//   CONSEQUENCE what may be decided on it
//
// Conflating them is how a true fact gets rendered as a claim it cannot
// support. Nothing in this file collapses the two, and nothing here mints a
// score, a percentage or a rail — an order is an order and a ceiling is an
// upper bound, never a grant.
//
// Kept free of QML types so these rules can be read, tested and argued with in
// one place.
// JOP-BRIDGE-001 binds this shipped implementation to the SPARK policy oracle.

// Nerd Font Material Design glyphs, built from codepoints rather than embedded
// literals so the source survives any re-encoding of this file.
var GLYPH = {
  verified:      String.fromCodePoint(0xF0565),  // shield-check
  degraded:      String.fromCodePoint(0xF0ECC),  // shield-alert
  refused:       String.fromCodePoint(0xF0ECC),  // shield-alert
  stale:         String.fromCodePoint(0xF0499),  // shield-outline
  indeterminate: String.fromCodePoint(0xF0499),  // shield-outline
  absent:        String.fromCodePoint(0xF0499),  // shield-outline
  pass:          String.fromCodePoint(0xF012C),  // check
  fail:          String.fromCodePoint(0xF0026),  // alert
  // arrow-to-line — a consequence held at its ceiling, strictly below the
  // assurance. This MUST NOT be the `fail` glyph: a cap is the ceiling doing
  // its job, not a failure, and sharing the alert triangle made a working
  // anti-laundering boundary read as a broken tool.
  capped:        String.fromCodePoint(0xF0792),
  refresh:       String.fromCodePoint(0xF0450),  // refresh
  copy:          String.fromCodePoint(0xF018F)   // content-copy
}

// ---------------------------------------------------------------------------
// State
//
// The widget reports in JACKAL's own status vocabulary, not a private one.
// `indeterminate` is a real verdict here for the same reason it is one in
// `claim_bundle_verify.py`: it means the input cannot support either answer,
// and rendering it as a soft pass would be the laundering this project exists
// to refuse.
//
//   absent         no runtime is installed for this user
//   indeterminate  installed, but nothing has been established in this session
//   stale          the last probe is older than the staleness window
//   refused        the CLI refused, or identity/runtime verification failed
//   degraded       probed, but a declared class did not execute at its class
//   verified       probed this session, fresh, identity matched, every class held

function classify(report, verify, nowMs, staleAfterSec) {
  if (!report) return "indeterminate"
  if (report.error) return "refused"
  if (report.installed === false) return "absent"

  if (report.identity_match === false) return "refused"
  if (verify && verify.verify && verify.verify !== "PASS") return "refused"

  var ageSec = (nowMs - report.receivedAtMs) / 1000
  if (isFinite(ageSec) && staleAfterSec > 0 && ageSec > staleAfterSec) return "stale"

  var probes = probeRows(report)
  if (probes.length === 0) return "indeterminate"
  for (var i = 0; i < probes.length; i++) {
    if (!probes[i].pass) return "degraded"
  }

  return report.doctor_verdict === "FUNCTIONAL" ? "verified" : "degraded"
}

function stateGlyph(state) {
  return GLYPH[state] || GLYPH.indeterminate
}

// Bar label. Deliberately terse; the panel carries the detail.
function stateLabel(state) {
  switch (state) {
  case "verified":      return "FUNCTIONAL"
  case "degraded":      return "DEGRADED"
  case "refused":       return "REFUSED"
  case "stale":         return "STALE"
  case "absent":        return "NOT INSTALLED"
  default:              return "INDETERMINATE"
  }
}

function stateBlurb(state, report) {
  switch (state) {
  case "verified":
    return "Every declared class executed at its declared class, in this session."
  case "degraded":
    return "Installed and probed, but a class did not execute at the class it declares."
  case "refused":
    return report && report.error ? report.error
      : "Identity or runtime verification did not pass. This is a refusal, not a warning."
  case "stale":
    return "The last probe is older than the staleness window, so it establishes nothing now."
  case "absent":
    return "No JACKAL runtime is installed for this user."
  default:
    return "Nothing has been established in this session. Indeterminate is not a soft pass."
  }
}

// Only a fresh, complete, this-session probe earns the undimmed treatment.
function isAffirmative(state) {
  return state === "verified"
}

function isAlarming(state) {
  return state === "refused" || state === "degraded"
}

// ---------------------------------------------------------------------------
// Session function — what actually ran here
//
// `doctor` executes one real tool per declared class and reports the status it
// came back with beside the status that class declares. That is the only thing
// on this surface that establishes FUNCTION, and only for the run that produced
// it.

function probeRows(report) {
  if (!report || !report.function || typeof report.function !== "object") return []
  var keys = Object.keys(report.function).sort()
  var rows = []
  for (var i = 0; i < keys.length; i++) {
    var entry = report.function[keys[i]] || {}
    rows.push({
      name: keys[i],
      tool: String(entry.tool || ""),
      executed: String(entry.executed_status || ""),
      expected: String(entry.expected || ""),
      pass: entry.functional_pass === true
    })
  }
  return rows
}

function passCount(report) {
  var rows = probeRows(report)
  var n = 0
  for (var i = 0; i < rows.length; i++) if (rows[i].pass) n++
  return n
}

// ---------------------------------------------------------------------------
// Capability — the declared surface
//
// `capability_inventory_v1.json` is the release's own generated account of its
// agent surface: for all forty-one tools, the assurance classes each may
// return, the consequence ceiling it may never exceed, the profiles it appears
// on, the fragment it admits, the boundary at which it refuses, and the exact
// identities its trust rests on.
//
// Nothing below computes a class. The parser takes the release's words apart at
// the field boundaries and hands them over intact.

// JACKAL's mathematical assurance axis, weakest to strongest, pinned by
// release/claim/inference_registry_v1.json#axis_orders.mathematical:
//
//   refused < indeterminate < estimated < model-based < checked < bounded
//           < formal-bounded < exact
//
// `exact` sits ABOVE `formal-bounded`, which is easy to get backwards: exact
// integer/rational computation is mathematically stronger than a certified
// enclosure, and is nonetheless OUTSIDE the Lean certificate chain. Strength on
// this axis and membership of the proof chain are different questions, and the
// register answers the second one by family.
var MATHEMATICAL_AXIS = [
  "refused", "indeterminate", "estimated", "model-based",
  "checked", "bounded", "formal-bounded", "exact"
]

// Rank is NOT position on that list. The registry pins the ranks separately
// (`axis_orders.mathematical_ranks`, and SPEC.md §4 item 3), and `estimated`
// and `model-based` share rank 2: an estimate and a result computed through an
// unvalidated model are equally strong mathematically, and neither dominates
// the other. Deriving rank from list position would silently promote
// `model-based` above `estimated` and shift every class above them.
//
// The list order above is still load-bearing: SPEC.md §4 breaks rank ties by
// first-listed, so it is the tie-breaker, not the rank.
var MATHEMATICAL_RANKS = {
  "refused":        0,
  "indeterminate":  1,
  "estimated":      2,
  "model-based":    2,
  "checked":        3,
  "bounded":        4,
  "formal-bounded": 5,
  "exact":          6
}

// The classes a tool can actually RETURN as an assurance: the axis without the
// two outcome states. `refused` is a status every tool declares, and
// `indeterminate` is a verdict about the input, so neither is part of the span
// a tool can be said to carry.
var MATHEMATICAL_RESULT_CLASSES = [
  "estimated", "model-based", "checked", "bounded", "formal-bounded", "exact"
]

// Consequence classes, weakest to strongest (release/claim/SPEC.md §4).
var CONSEQUENCE_AXIS = [
  "informational", "advisory", "decision-boundary", "safety-critical"
]

// SPEC.md §4: each consequence class mandates a MINIMUM mathematical strength
// on the decision node. The floor is what the class is entitled to stand on, so
// it is the only honest thing to compare an assurance ceiling against.
var CONSEQUENCE_FLOOR = {
  "informational":     "estimated",
  "advisory":          "checked",
  "decision-boundary": "bounded",
  "safety-critical":   "formal-bounded"
}

function axisRank(axis, value) {
  var i = axis.indexOf(String(value))
  return i < 0 ? -1 : i
}

// Rank on the mathematical axis, from the registry's rank map. -1 means the
// value is not on that axis at all (structural-exact, verified-program-evidence
// and friends), which is a different statement from "ranks lowest".
function mathRank(value) {
  var r = MATHEMATICAL_RANKS[String(value)]
  return r === undefined ? -1 : r
}

// Position in the registry's listed order, used only to break rank ties
// deterministically (SPEC.md §4: "ties broken by first-listed").
function mathListedIndex(value) {
  return axisRank(MATHEMATICAL_AXIS, value)
}

// True when these declared classes cover every class a tool can return. Such a
// tool does not sit at a class — it carries whatever the evidence establishes.
// Requiring the WHOLE span matters: a tool declaring two neighbouring classes
// carries a range, not the axis, and saying otherwise would overstate it.
function coversMathematicalSpan(classes) {
  var list = classes || []
  if (list.length < MATHEMATICAL_RESULT_CLASSES.length) return false
  for (var i = 0; i < MATHEMATICAL_RESULT_CLASSES.length; i++) {
    if (list.indexOf(MATHEMATICAL_RESULT_CLASSES[i]) < 0) return false
  }
  return true
}

// The strongest class a tool may return, on the mathematical axis. Tools whose
// declared set is off that axis (structural, program evidence, `ok`) return
// their declared class unchanged rather than being forced onto it.
function assuranceCeiling(classes) {
  var list = classes || []
  if (list.length === 0) return ""
  var best = "", bestRank = -1
  for (var i = 0; i < list.length; i++) {
    var r = mathRank(list[i])
    if (r < 0) continue
    // Strictly greater wins; equal rank falls back to the registry's listed
    // order so `estimated` and `model-based` resolve the same way every time
    // instead of depending on the order the inventory happened to list them.
    if (r > bestRank ||
        (r === bestRank && mathListedIndex(list[i]) < mathListedIndex(best))) {
      bestRank = r
      best = list[i]
    }
  }
  return bestRank >= 0 ? best : String(list[0])
}

// True when a declared consequence ceiling sits strictly below the assurance
// the family already establishes: the family proves more than it is permitted
// to decide on. That gap is the anti-laundering boundary, and the only thing
// worth marking — a declaration on its own is not a cap.
//
// Both sides must be on the mathematical axis for the comparison to mean
// anything. A family whose assurance is off that axis (structural-exact,
// verified-program-evidence) is NOT marked: there is no honest way to rank a
// structural fact against a mathematical floor, and marking it anyway would
// print an anti-laundering finding the evidence does not support. Same
// reasoning as sortByAxisDescending. A family that carries the whole axis sits
// at no single class, so it has no ceiling to be capped below either.
function consequenceCapsAssurance(assuranceClasses, declaredConsequences, carriesAxis) {
  if (carriesAxis) return false
  var declared = declaredConsequences || []
  if (declared.length === 0) return false
  var assuranceRank = mathRank(assuranceCeiling(assuranceClasses))
  if (assuranceRank < 0) return false
  // The strongest consequence the family may reach; a cap has to hold for it.
  var bestFloor = -1
  for (var i = 0; i < declared.length; i++) {
    var floor = CONSEQUENCE_FLOOR[declared[i]]
    var rank = floor === undefined ? -1 : mathRank(floor)
    if (rank > bestFloor) bestFloor = rank
  }
  if (bestFloor < 0) return false
  return bestFloor < assuranceRank
}

// The families the release declares, in the order this panel presents them:
// what actually stands behind the answer, strongest backing first. A family the
// inventory names but this table does not is kept and shown last rather than
// dropped — a surface that grew is a thing to show, not to hide.
var FAMILY_ORDER = [
  "lean-range", "lean-gaussian", "lean-int-cert", "lean-receipt-registry",
  "claim-router", "claim-verifier",
  "exact-cert-verifier", "runtime-only",
  "structural-checker", "decision-checker", "program-verifier"
]

// What stands behind an answer from this family. One sentence, and it must be
// the honest one — including for `runtime-only`, where the honest sentence is
// that nothing independent re-checks the result.
var FAMILY_BACKING = {
  "lean-range":
    "A Lean-proved checker accepted the certificate for this exact request.",
  "lean-gaussian":
    "A Lean-proved zero-libm checker accepted the Gaussian certificate.",
  "lean-int-cert":
    "A Lean-proved checker re-checked the whole subdivision tree against the raw request.",
  "lean-receipt-registry":
    "Re-runs the pinned Lean checker over an existing receipt's embedded certificate.",
  "claim-router":
    "Compiles a content-addressed evidence graph; refuses rather than downgrading.",
  "claim-verifier":
    "Replays a graph against caller-pinned expectations, trusting nothing that produced it.",
  "exact-cert-verifier":
    "Exact computation carrying a certificate an independent verifier recomputes.",
  "runtime-only":
    "The pinned engine, and nothing else. No certificate, no independent re-check.",
  "structural-checker":
    "A checker recomputes byte facts about source from the real bytes on disk.",
  "decision-checker":
    "A checker recomputes the ordering and margin from the caller's own numbers.",
  "program-verifier":
    "Approved Z3 UNSAT plus independent RUP replay. The artifact is never executed."
}

function familyRank(name) {
  var i = FAMILY_ORDER.indexOf(String(name))
  return i < 0 ? FAMILY_ORDER.length : i
}

function familyBacking(name) {
  return FAMILY_BACKING[String(name)] || ""
}

// Parse the release's generated capability inventory. Returns null for anything
// that is not the schema this widget knows how to read — a surface we cannot
// name is a surface we must not summarise.
function parseInventory(text) {
  var doc = null
  try {
    doc = JSON.parse(String(text || ""))
  } catch (e) {
    return null
  }
  if (!doc || doc.schema !== "jackal-capability-inventory-v1") return null
  if (!doc.tools || !doc.tools.length) return null

  var tools = []
  var toolsWithoutRefused = []

  for (var i = 0; i < doc.tools.length; i++) {
    var t = doc.tools[i] || {}
    var statusClasses = t.status_classes || []
    if (statusClasses.indexOf("refused") < 0) toolsWithoutRefused.push(String(t.name || "?"))

    var identities = (t.dependency && t.dependency.identities) || []
    var labels = []
    for (var d = 0; d < identities.length; d++) labels.push(String(identities[d].label || ""))

    tools.push({
      name: String(t.name || ""),
      assuranceClasses: (t.assurance_classes || []).slice(),
      assurance: assuranceCeiling(t.assurance_classes),
      // `null` in the inventory means the release declares no consequence
      // ceiling for this tool. That is not "safety-critical by default" — it is
      // "not declared", and it is rendered as such.
      consequence: t.consequence_ceiling === null || t.consequence_ceiling === undefined
        ? "" : String(t.consequence_ceiling),
      statusClasses: statusClasses.slice(),
      profiles: (t.profiles || []).slice(),
      family: String((t.dependency && t.dependency.family) || ""),
      fragment: String(t.supported_fragment || ""),
      refusalBoundary: String(t.refusal_boundary || ""),
      identityLabels: labels
    })
  }

  return {
    schema: String(doc.schema),
    release: doc.release ? String(doc.release.version || doc.release.state || "") : "",
    toolCount: typeof doc.tool_count === "number" ? doc.tool_count : tools.length,
    statusVocabulary: (doc.status_vocabulary || []).slice(),
    catalogSha: doc.catalog ? String(doc.catalog.sha256 || "") : "",
    tools: tools,
    // Stated as an observation of these exact bytes, never as a standing law.
    // The names are carried, not just the boolean, because a surface where the
    // law has stopped holding must be able to say WHICH tool broke it — a bare
    // false that renders as silence is the failure this widget exists to
    // refuse.
    everyToolDeclaresRefused: toolsWithoutRefused.length === 0,
    toolsWithoutRefused: toolsWithoutRefused
  }
}

// Group the surface by what stands behind it. Each row carries both axes and
// never merges them.
function familyRows(inventory) {
  if (!inventory) return []

  var byFamily = {}
  for (var i = 0; i < inventory.tools.length; i++) {
    var tool = inventory.tools[i]
    var key = tool.family || "(unnamed)"
    if (!byFamily[key]) {
      byFamily[key] = {
        family: key,
        backing: familyBacking(key),
        tools: [],
        assuranceSet: [],
        consequenceSet: [],
        profileSet: [],
        // True when any tool here declares the WHOLE mathematical result span:
        // it does not sit at a class, it carries whatever the evidence
        // establishes. The claim front doors are the case this exists for.
        // Declaring merely more than one class is a range, not the axis.
        carriesAxis: false
      }
    }
    var row = byFamily[key]
    row.tools.push(tool.name)
    // The union of every class the family's tools may RETURN, not the set of
    // their ceilings. A tool that may return `checked` or `bounded` does not
    // sit at `bounded`; collapsing it to its ceiling here would print the
    // stronger of the two as if it were the only one it could reach.
    if (tool.assuranceClasses.length === 0) {
      pushUnique(row.assuranceSet, tool.assurance)
    } else {
      for (var a = 0; a < tool.assuranceClasses.length; a++) {
        pushUnique(row.assuranceSet, tool.assuranceClasses[a])
      }
    }
    if (coversMathematicalSpan(tool.assuranceClasses)) row.carriesAxis = true
    pushUnique(row.consequenceSet, tool.consequence)
    for (var p = 0; p < tool.profiles.length; p++) pushUnique(row.profileSet, tool.profiles[p])
  }

  var rows = []
  for (var name in byFamily) {
    var r = byFamily[name]
    r.toolCount = r.tools.length
    // A tool that declares the whole axis does not sit at a class — it carries
    // whatever the evidence establishes. Say that, instead of printing six
    // words that would read as a claim to the strongest of them.
    // A family whose tools sit at several classes is shown as the set, ordered
    // strongest-first on the axis. An unordered list would read as if the
    // family were entitled to the strongest of them.
    r.assurance = r.carriesAxis
      ? "carries the axis"
      : (r.assuranceSet.length === 1
         ? r.assuranceSet[0]
         : sortByAxisDescending(r.assuranceSet).join(" / "))
    var declared = sortConsequencesDescending(
      r.consequenceSet.filter(function(c) { return c !== "" }))
    r.consequence = declared.length === 0 ? "not declared" : declared.join(" / ")
    r.consequenceDeclared = declared.length > 0
    // The load-bearing half: a consequence ceiling strictly below the assurance
    // ceiling is the anti-laundering boundary, and it is marked.
    r.capped = consequenceCapsAssurance(r.assuranceSet, declared, r.carriesAxis)
    r.profiles = r.profileSet.slice().sort()
    rows.push(r)
  }

  rows.sort(function(a, b) {
    var ra = familyRank(a.family), rb = familyRank(b.family)
    return ra === rb ? String(a.family).localeCompare(String(b.family)) : ra - rb
  })
  return rows
}

function pushUnique(list, value) {
  if (list.indexOf(value) < 0) list.push(value)
}

// Strongest first on the mathematical axis. Classes that are not on that axis
// (structural, program evidence) keep their relative order and follow the ones
// that are, because there is no honest way to rank them against it.
function sortByAxisDescending(values) {
  var onAxis = [], offAxis = []
  for (var i = 0; i < values.length; i++) {
    if (mathRank(values[i]) >= 0) onAxis.push(values[i])
    else offAxis.push(values[i])
  }
  onAxis.sort(function(a, b) {
    var byRank = mathRank(b) - mathRank(a)
    // Equal rank is a real possibility on this axis, so order the tie by the
    // registry's listed order rather than leaving it to the input's.
    return byRank !== 0 ? byRank : mathListedIndex(a) - mathListedIndex(b)
  })
  return onAxis.concat(offAxis)
}

// Strongest consequence first. The assurance side is already ordered on its
// axis because an unordered list reads as a claim to the strongest member; the
// consequence side carries exactly the same hazard and gets the same treatment.
function sortConsequencesDescending(values) {
  return values.slice().sort(function(a, b) {
    return axisRank(CONSEQUENCE_AXIS, b) - axisRank(CONSEQUENCE_AXIS, a)
  })
}

// ---------------------------------------------------------------------------
// Latest results — what this machine actually computed
//
// JACKAL is stateless per call: it answers and forgets, and the release stores
// no history. The MCP wrapper (`~/.local/bin/jackal-mcp-ledger`) records each
// tools/call into a JSONL ledger so this panel can show recent work. The
// wrapper sits OUTSIDE the identity-pinned plugin tree and only copies traffic
// it forwards; it cannot alter an answer.
//
// Nothing below reclassifies anything. `status`, `lane` and the engine's own
// output line are reproduced as JACKAL emitted them. A refusal is shown as a
// refusal, with its NAMED reason — the release's whole discipline is that it
// refuses rather than downgrading, and a panel that rendered a refusal as a
// soft "no result" would be laundering it back.
//
// What this section is NOT: evidence. Every other account on this panel is
// re-derived from something the release signed or from a tool executed in this
// session. These rows are a local record of calls that already happened,
// written by a wrapper, into an ordinary file. Nothing here re-verifies them,
// and an edited ledger would render identically to a real answer. The panel
// says so on screen rather than leaving the reader to assume otherwise — an
// unmarked recall sitting beside verified accounts would borrow their standing.

// Ten: the mission-control telemetry column has the vertical room for a real
// feed while other accounts keep their own columns. The ledger keeps far more
// (MAX_ENTRIES in the wrapper); this is only what is shown.
var RESULT_LIMIT = 10

function parseResults(text) {
  var lines = String(text || "").split("\n")
  var rows = []
  // Newest last in the file, newest first on screen.
  for (var i = lines.length - 1; i >= 0 && rows.length < RESULT_LIMIT; i--) {
    var line = lines[i].replace(/^\s+|\s+$/g, "")
    if (line === "") continue
    var entry = null
    try {
      entry = JSON.parse(line)
    } catch (e) {
      continue
    }
    if (!entry || typeof entry !== "object" || !entry.tool) continue
    rows.push(resultRow(entry))
  }
  return rows
}

function resultRow(entry) {
  var status = String(entry.status || "")
  var refused = status === "refused"
  return {
    tool: String(entry.tool || ""),
    status: status === "" ? "unknown" : status,
    lane: String(entry.lane || ""),
    refused: refused,
    formal: entry.formal === true,
    atMs: typeof entry.ts === "number" ? entry.ts * 1000 : 0,
    request: resultRequestText(entry),
    detail: refused ? resultRefusalText(entry) : resultAnswerText(entry),
    // Present only on a formal receipt. It is what makes a row checkable at
    // all: the digest names a receipt that can be re-verified through a front
    // door. A row without one is recall and nothing more.
    digest: String(entry.receipt_digest_sha256 || ""),
    // Whether the receipt itself was retained. Deliberately a BOOLEAN and not
    // the path: the panel rebuilds the path from the digest instead, so a
    // tampered ledger cannot steer a file read anywhere it likes. Without
    // retention the digest names evidence that no longer exists.
    retained: String(entry.receipt_path || "") !== ""
  }
}

// The engine's own first output line, minus the `status=` prefix the row already
// prints in its own column. Certificate-bearing lanes emit the whole certificate
// after a newline; that belongs in a receipt, not in a six-row summary.
function resultAnswerText(entry) {
  var out = String(entry.engine_output || "").split("\n")[0]
  if (out === "") out = String(entry.display_summary || "")
  return out.replace(/^status=\S+\s*/, "")
}

// A refusal must arrive named. If it somehow did not, say exactly that rather
// than inventing a reason or printing a bare word.
function resultRefusalText(entry) {
  var reason = String(entry.reason || "")
  var detail = String(entry.detail || "")
  if (reason !== "" && detail !== "") return reason + " — " + detail
  if (detail !== "") return detail
  if (reason !== "") return reason
  return "refused without a stated reason"
}

// What was actually asked. Echoing the request is not decoration: the README
// names transcription at the model/tool boundary as the dominant failure, and
// an answer whose input cannot be seen cannot be checked.
function resultRequestText(entry) {
  var args = entry.arguments
  if (!args || typeof args !== "object") return ""
  var keys = Object.keys(args).sort()
  var parts = []
  for (var i = 0; i < keys.length && i < 4; i++) {
    parts.push(keys[i] + "=" + String(args[keys[i]]).slice(0, 60))
  }
  return parts.join("  ")
}

// ---------------------------------------------------------------------------
// Profiles — the operator's actual lever
//
// A profile is what an agent is allowed to reach. Widening one is an explicit
// operator act, and these three sentences are the reason each exists.

var PROFILE_MEANING = {
  core:
    "Verification front doors only. Every number arrives inside a replayable graph.",
  formal:
    "Core plus the lanes that terminate in a Lean-proved checker.",
  full:
    "The complete surface, for operator-driven use where a human reads each status."
}

function profileRows(inventory) {
  if (!inventory) return []

  // Counted from the per-tool membership the release declares, rather than
  // read off a separate summary that could drift from it.
  var counts = {}
  for (var i = 0; i < inventory.tools.length; i++) {
    var profiles = inventory.tools[i].profiles
    for (var p = 0; p < profiles.length; p++) {
      if (counts[profiles[p]] === undefined) counts[profiles[p]] = 0
      counts[profiles[p]]++
    }
  }

  var order = ["core", "formal", "full"]
  var rows = []
  for (var k = 0; k < order.length; k++) {
    var name = order[k]
    if (counts[name] === undefined) continue
    rows.push({
      name: name,
      count: counts[name],
      meaning: PROFILE_MEANING[name] || ""
    })
  }
  return rows
}

// ---------------------------------------------------------------------------
// Verification — the front door
//
// This is the one place the widget stops describing JACKAL and acts on it. In
// the `core` profile an agent must verify before it can speak; a widget that
// only rendered that rule while never exercising it would be describing a
// discipline it does not keep.
//
// The verdict is produced by `jackal_verify_receipt` / `jackal_verify_bundle`
// and passed through verbatim. Nothing here computes a status, softens a
// refusal, or retries on a weaker lane.

var VERIFY_SCHEMA = "khephri.jackal-verify-v1"

// `raised_by` is load-bearing and must never be flattened away. A refusal from
// the widget means the artifact never reached a front door — the operator's
// authorization was missing, or the clipboard held something else. A refusal
// from JACKAL means the front door looked and said no. Rendering those two the
// same way would let a routing failure read as a verification result.
function verifyRaisedByText(result) {
  if (!result) return ""
  return result.raised_by === "jackal"
    ? "refused by the JACKAL front door"
    : "refused by this widget before the front door was reached"
}

function verifyStatusLabel(status) {
  switch (String(status)) {
  case "verified":      return "VERIFIED"
  case "refused":       return "REFUSED"
  case "indeterminate": return "INDETERMINATE"
  default:              return "NOT RUN"
  }
}

function verifyIsAffirmative(result) {
  return !!result && result.status === "verified"
}

// Any refusal at all — used to decide whether to explain WHERE it came from.
function verifyIsRefusal(result) {
  return !!result && result.status === "refused"
}

// Only a refusal from the FRONT DOOR is alarming.
//
// A refusal raised by this widget means the artifact never reached JACKAL at
// all: an empty clipboard, text that is not JSON, a missing authorization.
// That establishes nothing, which is `dim` — the same colour as every other
// not-established state here. Rendering it in the refusal colour says "JACKAL
// looked at your evidence and rejected it" when JACKAL was never consulted,
// and pressing `p` with an ordinary string in the clipboard would read as a
// failure of the kernel rather than as nothing to check.
//
// A refusal raised by `jackal` IS a verdict about evidence, and stays urgent.
function verifyIsAlarming(result) {
  return verifyIsRefusal(result) && result.raised_by === "jackal"
}

// The operator's authorization, rendered so "why did it refuse?" is answerable
// on screen. Showing this is not decoration: an authorization the operator
// cannot see is one they cannot audit.
function authorizedRows(result) {
  if (!result || !result.authorized) return []
  var keys = Object.keys(result.authorized).sort()
  var rows = []
  for (var i = 0; i < keys.length; i++) {
    var value = result.authorized[keys[i]]
    rows.push({
      name: String(keys[i]).replace(/^expected_/, ""),
      value: typeof value === "string" ? value : JSON.stringify(value)
    })
  }
  return rows
}

// One line naming exactly what was checked, so a verdict can be tied to bytes.
function verifySubject(result) {
  if (!result) return ""
  var parts = []
  if (result.artifact_kind) parts.push(result.artifact_kind)
  if (result.artifact_sha256) parts.push(shortHash(result.artifact_sha256))
  if (result.tool) parts.push("via " + result.tool)
  return parts.join(" · ")
}

// ---------------------------------------------------------------------------
// Formatting

function shortHash(hash) {
  var value = String(hash || "")
  return value.length > 16 ? value.slice(0, 8) + "…" + value.slice(-8) : value
}

function ageText(receivedAtMs, nowMs) {
  if (!receivedAtMs) return "never"
  var sec = Math.max(0, Math.round((nowMs - receivedAtMs) / 1000))
  if (sec < 5) return "just now"
  if (sec < 60) return sec + "s ago"
  if (sec < 3600) return Math.round(sec / 60) + "m ago"
  if (sec < 86400) return Math.round(sec / 3600) + "h ago"
  return Math.round(sec / 86400) + "d ago"
}

function pluralAnswers(n) {
  return n === 1 ? "1 answer" : n + " answers"
}

function pluralTools(n) {
  return n === 1 ? "1 tool" : n + " tools"
}

// The bar tooltip has to survive being the only thing the user reads, so it
// carries the state, the runtime, what was established, and when — and never
// implies more than that.
function tooltip(state, report, receivedAtMs, nowMs) {
  var lines = ["JACKAL + THOTH — " + stateLabel(state)]
  if (report && report.capability && report.capability.package_epoch)
    lines.push("Runtime " + report.capability.package_epoch)
  var rows = probeRows(report)
  if (rows.length > 0)
    lines.push(passCount(report) + "/" + rows.length + " classes executed at their class")
  lines.push("Probed " + ageText(receivedAtMs, nowMs))
  return lines.join("\n")
}

// ---------------------------------------------------------------------------
// `jackal maturity` — the engine's governing non-claim
//
// The whole graded inventory is available here, but the panel needs one line of
// it: the last line the engine prints, which is the project's own statement of
// what no amount of testing establishes. It is read from the same runtime whose
// epoch the doctor probe established, and it is never paraphrased.

function parseNonClaim(text) {
  var lines = String(text || "").split("\n")
  for (var i = lines.length - 1; i >= 0; i--) {
    var line = lines[i].trim()
    if (line.indexOf("non-claim=") === 0) return line.slice("non-claim=".length).trim()
  }
  return ""
}

// ---------------------------------------------------------------------------
// Live graph deck — untrusted presentation over sealed-evaluator samples.
//
// The widget never computes a sample. It substitutes a literal x into the
// caller's expression, hands whole sweeps to the runtime's own evaluator
// binary in bounded worksheet batches, and plots exactly what came back.
// A statement the evaluator refuses (domain error, division by zero) becomes
// a break in the curve, never an invented value. The rendered pixels remain
// estimated visualization and are not proof of continuity, roots, extrema,
// or anything between samples.

var GRAPH_SAMPLE_COUNT = 96
var GRAPH_CHUNK_SIZE = 12
var GRAPH_EXPRESSION_LIMIT = 240
var GRAPH_RANGE_LIMIT = 1000000
var GRAPH_MIN_SPAN = 0.000001

// Only the expression fragment the engine's eval grammar can hold: digits,
// the variable x, lowercase function names, +-*/^, parentheses, dots,
// commas and spaces. Anything else is refused before a subprocess exists.
function graphExpressionValid(expr) {
  var text = String(expr || "")
  if (text.trim() === "" || text.length > GRAPH_EXPRESSION_LIMIT) return false
  return /^[0-9a-z+\-*/^(). ,]+$/.test(text)
}

function graphRangeValid(xMin, xMax) {
  var lo = Number(xMin), hi = Number(xMax)
  if (!isFinite(lo) || !isFinite(hi)) return false
  if (Math.abs(lo) > GRAPH_RANGE_LIMIT || Math.abs(hi) > GRAPH_RANGE_LIMIT) return false
  return hi - lo >= GRAPH_MIN_SPAN
}

// Plain-decimal rendering the eval grammar accepts: never e-notation.
function graphNumberText(value) {
  var text = Number(value).toFixed(8)
  text = text.replace(/0+$/, "").replace(/\.$/, "")
  if (text === "-0") text = "0"
  return text
}

// Replace each standalone `x` with the parenthesized literal. A character
// walk instead of lookbehind regex keeps this portable across JS engines.
function graphSubstitute(expr, xText) {
  var source = String(expr || "")
  var out = ""
  for (var i = 0; i < source.length; i++) {
    var ch = source[i]
    if (ch !== "x") { out += ch; continue }
    var prev = i > 0 ? source[i - 1] : ""
    var next = i + 1 < source.length ? source[i + 1] : ""
    var boundary = /[0-9a-z.]/
    if (boundary.test(prev) || boundary.test(next)) { out += ch; continue }
    out += "(" + xText + ")"
  }
  return out
}

function graphXValues(xMin, xMax, samples) {
  var count = Math.max(2, Math.min(GRAPH_SAMPLE_COUNT, Number(samples) || GRAPH_SAMPLE_COUNT))
  var lo = Number(xMin), hi = Number(xMax)
  var values = []
  for (var i = 0; i < count; i++) {
    values.push(lo + (hi - lo) * i / (count - 1))
  }
  return values
}

// One worksheet argument for a batch of samples: `f(x0); f(x1); ...`.
function graphWorksheet(expr, xNumbers) {
  var statements = []
  for (var i = 0; i < xNumbers.length; i++) {
    statements.push(graphSubstitute(expr, graphNumberText(xNumbers[i])))
  }
  return statements.join("; ")
}

// Worksheet stdout is one plain value per statement line. Any line that is
// not a finite number (or any shortfall after a mid-sweep refusal) yields
// null — a break, not a value.
function parseWorksheetValues(text, expected) {
  var lines = String(text || "").split("\n")
  var values = []
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line === "") continue
    var value = Number(line)
    values.push(isFinite(value) ? value : null)
  }
  while (values.length < expected) values.push(null)
  return values.slice(0, expected)
}

function graphMetaText(points) {
  var total = points.length
  var refused = 0
  for (var i = 0; i < total; i++) if (points[i].y === null) refused++
  var meta = total + " samples · sealed evaluator f64"
  if (refused > 0) meta += " · " + refused + " refused (curve breaks)"
  return meta
}

// Instrument ticks: gridlines land on 1/2/5 × 10^k values so every line the
// eye crosses names a number a person can hold. Returns the step so labels
// can choose exactly the decimals the step needs — no ten-digit corner noise.
function graphTicks(lo, hi, target) {
  if (!isFinite(lo) || !isFinite(hi) || !(hi > lo)) return { step: 1, ticks: [] }
  var raw = (hi - lo) / Math.max(2, Number(target) || 5)
  var magnitude = Math.pow(10, Math.floor(Math.log(raw) / Math.LN10))
  var norm = raw / magnitude
  var step = magnitude * (norm < 1.5 ? 1 : norm < 3 ? 2 : norm < 7 ? 5 : 10)
  var ticks = []
  var first = Math.ceil(lo / step - 1e-9) * step
  for (var value = first; value <= hi + step * 1e-9 && ticks.length < 12; value += step) {
    var snapped = Math.abs(value) < step * 1e-9 ? 0 : value
    ticks.push(snapped)
  }
  return { step: step, ticks: ticks }
}

// A tick label carries exactly the precision its step justifies.
function graphTickLabel(value, step) {
  var decimals = 0
  if (isFinite(step) && step > 0 && step < 1) {
    decimals = Math.min(6, Math.ceil(-Math.log(step) / Math.LN10))
  }
  var text = Number(value).toFixed(decimals)
  if (/^-0(\.0+)?$/.test(text)) text = text.slice(1)
  return text
}

// Contiguous refused runs as x spans, widened half a sample step each side,
// so the band covers the ground the refusal actually owns — the samples that
// refused — and no more.
function graphRefusedRuns(points) {
  var runs = []
  if (!points || points.length < 2) return runs
  var half = (points[points.length - 1].x - points[0].x) / (points.length - 1) / 2
  var start = -1
  for (var i = 0; i <= points.length; i++) {
    var refused = i < points.length && points[i].y === null
    if (refused && start < 0) start = i
    if (!refused && start >= 0) {
      runs.push({ x0: points[start].x - half, x1: points[i - 1].x + half })
      start = -1
    }
  }
  return runs
}

// The sweep's own extremes — evaluator samples, not window padding — so the
// instrument can mark where the observed maximum and minimum actually sit.
function graphExtremes(points) {
  var min = null, max = null
  for (var i = 0; i < (points ? points.length : 0); i++) {
    var p = points[i]
    if (p.y === null) continue
    if (min === null || p.y < min.y) min = { x: p.x, y: p.y }
    if (max === null || p.y > max.y) max = { x: p.x, y: p.y }
  }
  return { min: min, max: max }
}

// Hover readout text: the nearest evaluator sample, named as a sample. The
// crosshair never interpolates — between samples there is no claim.
function graphHoverText(point, index, total) {
  if (!point) return ""
  var base = "x " + graphNumberText(point.x)
  if (point.y === null) return base + " · refused · sample " + (index + 1) + "/" + total
  return base + " · f " + graphNumberText(point.y) + " · sample " + (index + 1) + "/" + total
}
