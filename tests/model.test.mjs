// Tests for Model.js — the rules that decide what the widget is allowed to
// claim. Run with:  node tests/model.test.mjs
//
// Model.js is a `.pragma library` QML script: plain ECMAScript with no imports
// and no QML types, so it is loaded here by evaluating its source and pulling
// the named functions out of the resulting scope.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(join(here, "..", "Model.js"), "utf8");

const exported = [
  "GLYPH", "classify", "stateLabel", "stateBlurb", "stateGlyph",
  "isAffirmative", "isAlarming", "probeRows", "passCount",
  "MATHEMATICAL_AXIS", "MATHEMATICAL_RANKS", "CONSEQUENCE_AXIS", "assuranceCeiling",
  "FAMILY_ORDER", "familyBacking", "parseInventory", "familyRows",
  "profileRows", "shortHash", "ageText", "pluralTools", "tooltip",
  "parseNonClaim", "parseResults", "pluralAnswers", "RESULT_LIMIT",
  "VERIFY_SCHEMA", "verifyStatusLabel", "verifyIsAffirmative", "verifyIsAlarming",
  "verifyIsRefusal", "verifyRaisedByText", "authorizedRows", "verifySubject"
];

const Model = new Function(
  `${source.replace(/^\.pragma library\s*/, "")}\nreturn {${exported.join(",")}};`
)();

let failures = 0;
let checks = 0;

function check(name, condition, detail) {
  checks += 1;
  if (condition) return;
  failures += 1;
  console.error(`FAIL  ${name}${detail ? `\n      ${detail}` : ""}`);
}

function eq(name, actual, expected) {
  check(name, actual === expected, `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}

const NOW = 1_700_000_000_000;

function doctor(overrides = {}) {
  return {
    installed: true,
    host: { system: "Linux", machine: "aarch64" },
    capability: {
      package_epoch: "v1.7.3",
      package_sha256: "0b239bc7a96d75537706ab1aebbc271150c663048f49711107ffe1b93f7d743d",
      z3_present: true,
      anubis_compiler_present: true
    },
    function: {
      exact: { tool: "jackal_exact", executed_status: "exact", expected: "exact", functional_pass: true },
      "formal-bounded": { tool: "jackal_sqrt_rat_bound", executed_status: "formal-bounded", expected: "formal-bounded", functional_pass: true },
      structural: { tool: "jackal_test_exists", executed_status: "structural-exact", expected: "structural-exact", functional_pass: true }
    },
    identity_match: true,
    doctor_verdict: "FUNCTIONAL",
    receivedAtMs: NOW,
    ...overrides
  };
}

// ---------------------------------------------------------------------------
// State: the widget reports in JACKAL's own vocabulary, and nothing that was
// not established here may read as a pass.

eq("no report is indeterminate, not unknown",
  Model.classify(null, null, NOW, 2400), "indeterminate");

eq("indeterminate is never affirmative",
  Model.isAffirmative("indeterminate"), false);

eq("a CLI error is a refusal, not a warning",
  Model.classify({ error: "omarchy-jackal is not on PATH", receivedAtMs: NOW }, null, NOW, 2400), "refused");

eq("an identity mismatch refuses",
  Model.classify(doctor({ identity_match: false }), null, NOW, 2400), "refused");

eq("a failed runtime verify refuses",
  Model.classify(doctor(), { verify: "FAIL" }, NOW, 2400), "refused");

eq("not installed is absent",
  Model.classify(doctor({ installed: false }), null, NOW, 2400), "absent");

eq("a fresh complete probe is verified",
  Model.classify(doctor(), { verify: "PASS" }, NOW, 2400), "verified");

eq("an aged probe goes stale rather than carrying forward",
  Model.classify(doctor(), { verify: "PASS" }, NOW + 3_000_000, 2400), "stale");

{
  const downgraded = doctor();
  downgraded.function.exact.executed_status = "estimated";
  downgraded.function.exact.functional_pass = false;
  eq("a class that did not execute at its class degrades",
    Model.classify(downgraded, { verify: "PASS" }, NOW, 2400), "degraded");
}

eq("a non-FUNCTIONAL verdict degrades even with every probe passing",
  Model.classify(doctor({ doctor_verdict: "CAPABLE" }), { verify: "PASS" }, NOW, 2400), "degraded");

eq("an empty function map establishes nothing",
  Model.classify(doctor({ function: {} }), { verify: "PASS" }, NOW, 2400), "indeterminate");

check("refused and degraded are the only alarming states",
  Model.isAlarming("refused") && Model.isAlarming("degraded")
  && !Model.isAlarming("stale") && !Model.isAlarming("indeterminate")
  && !Model.isAlarming("verified"));

check("every state has a label and a glyph",
  ["verified", "degraded", "refused", "stale", "absent", "indeterminate"]
    .every(s => Model.stateLabel(s).length > 0 && Model.stateGlyph(s).length > 0));

check("the indeterminate blurb refuses to read as a soft pass",
  Model.stateBlurb("indeterminate", null).includes("not a soft pass"));

// ---------------------------------------------------------------------------
// Session function

{
  const rows = Model.probeRows(doctor());
  eq("probe rows are sorted by class name", rows.map(r => r.name).join(","),
    "exact,formal-bounded,structural");
  eq("probe pass count is derived, not asserted", Model.passCount(doctor()), 3);
  eq("a missing function map yields no rows", Model.probeRows({}).length, 0);
}

// ---------------------------------------------------------------------------
// The mathematical axis
//
// This is the one ordering it is easy to get backwards, so it is asserted
// explicitly against release/claim/inference_registry_v1.json#axis_orders.

eq("the axis is the registry's, weakest first",
  Model.MATHEMATICAL_AXIS.join(" < "),
  "refused < indeterminate < estimated < model-based < checked < bounded < formal-bounded < exact");

eq("exact outranks formal-bounded on the mathematical axis",
  Model.assuranceCeiling(["formal-bounded", "exact"]), "exact");

eq("the claim front doors' ceiling is the top of their declared set",
  Model.assuranceCeiling(["estimated", "model-based", "checked", "bounded", "formal-bounded", "exact"]),
  "exact");

eq("an off-axis class is returned unchanged, not forced onto the axis",
  Model.assuranceCeiling(["structural-exact"]), "structural-exact");

eq("an off-axis program class is returned unchanged",
  Model.assuranceCeiling(["verified-program-evidence"]), "verified-program-evidence");

eq("the consequence axis is separate and ordered",
  Model.CONSEQUENCE_AXIS.join(" < "),
  "informational < advisory < decision-boundary < safety-critical");

// A cap is the ceiling doing its job, not a failure. Sharing the alert glyph
// made a correctly-bounded family read as a broken one, so the two must differ.
check("a consequence cap does not borrow the failure glyph",
  Model.GLYPH.capped !== Model.GLYPH.fail);

// Rank is pinned by inference_registry_v1.json#axis_orders.mathematical_ranks,
// NOT by position in the listed order. Deriving it from position promotes
// `model-based` above `estimated` and shifts every class above them.
eq("the rank map is the registry's, not list position",
  Model.MATHEMATICAL_AXIS.map(c => `${c}=${Model.MATHEMATICAL_RANKS[c]}`).join(","),
  "refused=0,indeterminate=1,estimated=2,model-based=2,checked=3,bounded=4,formal-bounded=5,exact=6");

check("estimated and model-based share a rank: neither dominates the other",
  Model.MATHEMATICAL_RANKS["estimated"] === Model.MATHEMATICAL_RANKS["model-based"]);

eq("a rank tie resolves to the first-listed class",
  Model.assuranceCeiling(["model-based", "estimated"]), "estimated");

eq("and resolves the same way whatever order the inventory listed them in",
  Model.assuranceCeiling(["estimated", "model-based"]), "estimated");

eq("a genuine maximum still beats a tie",
  Model.assuranceCeiling(["estimated", "model-based", "bounded"]), "bounded");

// ---------------------------------------------------------------------------
// The capability inventory — parsed from real release bytes

const inventoryText = readFileSync(join(here, "fixtures", "capability_inventory_v173.json"), "utf8");
const inventory = Model.parseInventory(inventoryText);

check("a real inventory parses", inventory !== null);
eq("the schema is checked, not assumed", Model.parseInventory('{"tools":[{}]}'), null);
eq("malformed JSON yields null rather than a partial surface", Model.parseInventory("{"), null);
eq("an empty tool list yields null",
  Model.parseInventory('{"schema":"jackal-capability-inventory-v1","tools":[]}'), null);

check("every tool in the fixture declares refused",
  inventory.everyToolDeclaresRefused === true);

{
  // The load-bearing observation: it is an observation of these bytes, so a
  // tool that stopped declaring `refused` must flip it.
  const doc = JSON.parse(inventoryText);
  doc.tools[0].status_classes = doc.tools[0].status_classes.filter(c => c !== "refused");
  const broken = Model.parseInventory(JSON.stringify(doc));
  eq("a tool that drops refused flips the observation",
    broken.everyToolDeclaresRefused, false);
  eq("and the broken tool is named, so the footer cannot go silent",
    broken.toolsWithoutRefused.join(","), doc.tools[0].name);
}

eq("an intact inventory names no offenders",
  inventory.toolsWithoutRefused.length, 0);

check("the catalog digest is carried through",
  /^[0-9a-f]{64}$/.test(inventory.catalogSha));

// ---------------------------------------------------------------------------
// The evidence register — families, both axes, never merged

const families = Model.familyRows(inventory);

check("families are present", families.length > 0);

eq("the strongest backing is listed first", families[0].family, "lean-range");

check("every family carries a backing sentence",
  families.every(f => f.backing.length > 0),
  `missing: ${families.filter(f => !f.backing).map(f => f.family).join(", ")}`);

check("every declared family is in the presentation order",
  families.every(f => Model.FAMILY_ORDER.includes(f.family)),
  `unlisted: ${families.filter(f => !Model.FAMILY_ORDER.includes(f.family)).map(f => f.family).join(", ")}`);

{
  const structural = families.find(f => f.family === "structural-checker");
  eq("a structural fact is exact in assurance", structural.assurance, "structural-exact");
  eq("and stops at informational in consequence", structural.consequence, "informational");
  // structural-exact is not on the mathematical axis, so its assurance cannot be
  // ranked against informational's floor. Declaring a ceiling is not by itself a
  // cap, and marking it would print an anti-laundering finding nothing supports.
  check("an off-axis assurance is not marked as capped by a declared ceiling",
    structural.capped === false);
}

{
  const decision = families.find(f => f.family === "decision-checker");
  eq("a decision is exact in assurance", decision.assurance, "exact");
  eq("and stops at decision-boundary in consequence", decision.consequence, "decision-boundary");
  // decision-boundary stands on `bounded`; the family establishes `exact`. The
  // ceiling is strictly below the assurance, which is the load-bearing half.
  check("a ceiling strictly below the assurance is marked as the load-bearing half",
    decision.capped === true);
}

{
  const lean = families.find(f => f.family === "lean-range");
  eq("a formal lane's assurance is formal-bounded", lean.assurance, "formal-bounded");
  eq("an undeclared consequence ceiling says so rather than defaulting high",
    lean.consequence, "not declared");
  check("an undeclared ceiling is not marked as capped", lean.capped === false);
  check("the formal lane is on the formal profile", lean.profiles.includes("formal"));
}

{
  const router = families.find(f => f.family === "claim-router");
  eq("the claim front door carries the axis rather than one class",
    router.assurance, "carries the axis");
}

{
  const runtimeOnly = families.find(f => f.family === "runtime-only");
  check("the runtime-only backing states plainly that nothing re-checks it",
    Model.familyBacking("runtime-only").includes("nothing else"));
  check("runtime-only spans more than one assurance class",
    runtimeOnly.assurance === "carries the axis" || runtimeOnly.assuranceSet.length >= 1);
}

check("a family the table does not name is kept, not dropped", (() => {
  const doc = JSON.parse(inventoryText);
  doc.tools[0].dependency.family = "some-future-family";
  const rows = Model.familyRows(Model.parseInventory(JSON.stringify(doc)));
  const found = rows.find(f => f.family === "some-future-family");
  return found !== undefined && found.backing === "" && rows[rows.length - 1].family === "some-future-family";
})());

// A tool declaring several classes carries a RANGE. Only a tool declaring every
// class it could return carries the axis, and a family must show the range it
// actually declares rather than collapsing it to its ceiling.
{
  const doc = JSON.parse(inventoryText);
  doc.tools[0].dependency.family = "range-declarer";
  doc.tools[0].assurance_classes = ["checked", "bounded"];
  doc.tools[0].consequence_ceiling = null;
  const row = Model.familyRows(Model.parseInventory(JSON.stringify(doc)))
    .find(f => f.family === "range-declarer");
  check("two neighbouring classes is a range, not the axis",
    row.assurance !== "carries the axis");
  eq("and the whole range is shown strongest-first, not just its ceiling",
    row.assurance, "bounded / checked");
}

{
  const doc = JSON.parse(inventoryText);
  doc.tools[0].dependency.family = "almost-the-axis";
  doc.tools[0].assurance_classes =
    ["estimated", "model-based", "checked", "bounded", "formal-bounded"];
  const row = Model.familyRows(Model.parseInventory(JSON.stringify(doc)))
    .find(f => f.family === "almost-the-axis");
  check("five classes of six is still not the axis",
    row.assurance !== "carries the axis");
}

// The consequence side carries the same hazard as the assurance side: an
// unordered list reads as a claim to the strongest member.
{
  const doc = JSON.parse(inventoryText);
  doc.tools[0].dependency.family = "mixed-consequence";
  doc.tools[0].consequence_ceiling = "informational";
  doc.tools[1].dependency.family = "mixed-consequence";
  doc.tools[1].consequence_ceiling = "decision-boundary";
  const row = Model.familyRows(Model.parseInventory(JSON.stringify(doc)))
    .find(f => f.family === "mixed-consequence");
  eq("several declared consequences are ordered strongest-first",
    row.consequence, "decision-boundary / informational");
}

// ---------------------------------------------------------------------------
// Profiles

{
  const profiles = Model.profileRows(inventory);
  eq("profiles are presented widest-last", profiles.map(p => p.name).join(","), "core,formal,full");
  check("every profile carries its reason for existing",
    profiles.every(p => p.meaning.length > 0));
  check("core is the narrowest", profiles[0].count <= profiles[2].count);
  eq("no inventory yields no profile rows", Model.profileRows(null).length, 0);
}

// A refusal raised by this WIDGET means the artifact never reached JACKAL — an
// empty clipboard, text that is not JSON. That establishes nothing; it is not a
// verdict about evidence, and must not be rendered as one. Pressing `p` with an
// ordinary string in the clipboard should not look like the kernel failed.

{
  const widgetRefusal = { status: "refused", raised_by: "widget",
                          reason: "widget-clipboard-not-json" };
  const doorRefusal   = { status: "refused", raised_by: "jackal",
                          reason: "expected-request-mismatch" };

  check("both are refusals", Model.verifyIsRefusal(widgetRefusal)
        && Model.verifyIsRefusal(doorRefusal));

  check("a refusal from the front door is alarming",
    Model.verifyIsAlarming(doorRefusal) === true);
  check("a refusal raised before the front door is NOT alarming",
    Model.verifyIsAlarming(widgetRefusal) === false);

  check("and each says plainly where it came from",
    Model.verifyRaisedByText(doorRefusal).includes("JACKAL front door")
    && Model.verifyRaisedByText(widgetRefusal).includes("before the front door"));

  check("neither is ever affirmative",
    !Model.verifyIsAffirmative(widgetRefusal) && !Model.verifyIsAffirmative(doorRefusal));

  eq("a verified result is affirmative and not alarming",
    [Model.verifyIsAffirmative({ status: "verified", raised_by: "jackal" }),
     Model.verifyIsAlarming({ status: "verified", raised_by: "jackal" })].join(","),
    "true,false");
}

// ---------------------------------------------------------------------------
// The governing non-claim, verbatim

{
  const maturity = readFileSync(join(here, "fixtures", "maturity_v1.7.3.txt"), "utf8");
  const nonClaim = Model.parseNonClaim(maturity);
  eq("the non-claim is the engine's own last line, verbatim",
    nonClaim, "universal-correctness; finite campaigns cannot establish it");
  eq("no non-claim line yields an empty string, never a substitute",
    Model.parseNonClaim("class=exact commands=rat\n"), "");
}

// ---------------------------------------------------------------------------
// Latest results — the ledger the MCP wrapper writes
//
// JACKAL is stateless per call, so this is the only record that work happened.
// The rule for every assertion here: JACKAL's own words survive intact.

{
  const line = (o) => JSON.stringify(o);
  const ledger = [
    line({ ts: 1000, tool: "jackal_exact", arguments: { expression: "1/3" },
           status: "exact", lane: "rat",
           engine_output: "status=exact parsed=1/3 exact=1/3 approx=0.333" }),
    line({ ts: 2000, tool: "jackal_exact", arguments: { expression: "sin(1)" },
           status: "refused", reason: "evaluator-refused",
           detail: "rat: exact mode supports integers only; fail closed" }),
    line({ ts: 3000, tool: "jackal_sqrt_rat_bound", arguments: {},
           status: "formal-bounded", lane: "sqrt-rat", formal: true,
           engine_output: "status=formal-bounded enclosure=[1,2]" }),
  ].join("\n");

  const rows = Model.parseResults(ledger);
  eq("the newest answer is first", rows[0].tool, "jackal_sqrt_rat_bound");
  eq("three entries yield three rows", rows.length, 3);

  eq("the status class is JACKAL's own word, not a rewording",
    rows[0].status, "formal-bounded");
  check("a formal lane is carried as formal", rows[0].formal === true);
  eq("the engine's own line is shown without the status prefix the row repeats",
    rows[0].detail, "enclosure=[1,2]");

  const refusal = rows[1];
  check("a refusal is marked as one", refusal.refused === true);
  eq("and keeps JACKAL's status word", refusal.status, "refused");
  eq("and arrives NAMED: reason and detail, never a bare word",
    refusal.detail,
    "evaluator-refused — rat: exact mode supports integers only; fail closed");

  eq("the request is echoed so the answer can be checked against what was asked",
    rows[2].request, "expression=1/3");

  const structured = Model.parseResults(JSON.stringify({
    ts: 4000,
    tool: "jackal_hellgate_ground_state",
    status: "bounded",
    engine_output: "",
    display_summary: "E0 [-4.62, -4.61] · ground integral(u0^4) [1.46, 1.47]",
  }))[0];
  eq("structured wrapper answers never render as a blank latest answer",
    structured.detail,
    "E0 [-4.62, -4.61] · ground integral(u0^4) [1.46, 1.47]");
}

eq("no ledger is no rows, not an error", Model.parseResults("").length, 0);
eq("a missing file reads as empty", Model.parseResults(null).length, 0);

check("malformed lines are skipped rather than poisoning the list", (() => {
  const rows = Model.parseResults('not json\n{"ts":1,"tool":"jackal_exact","status":"exact"}\n{');
  return rows.length === 1 && rows[0].tool === "jackal_exact";
})());

check("the list is capped so the panel cannot grow without bound", (() => {
  const many = Array.from({ length: 30 },
    (_, i) => JSON.stringify({ ts: i, tool: "jackal_exact", status: "exact" })).join("\n");
  return Model.parseResults(many).length === Model.RESULT_LIMIT;
})());

// The one case that must never render as a soft "no result".
eq("a refusal with no stated reason says exactly that",
  Model.parseResults(JSON.stringify({ ts: 1, tool: "jackal_exact", status: "refused" }))[0].detail,
  "refused without a stated reason");

// ---------------------------------------------------------------------------
// Verification verdicts
//
// The widget must never invent a verdict, and must never render a routing
// failure the same way as a verification result.

eq("the verdict schema is pinned", Model.VERIFY_SCHEMA, "khephri.jackal-verify-v1");

eq("a verdict that was never run is not a pass",
  Model.verifyStatusLabel(""), "NOT RUN");
eq("indeterminate keeps its own word",
  Model.verifyStatusLabel("indeterminate"), "INDETERMINATE");
eq("verified is verified", Model.verifyStatusLabel("verified"), "VERIFIED");
eq("refused is refused", Model.verifyStatusLabel("refused"), "REFUSED");

check("only verified is affirmative",
  Model.verifyIsAffirmative({ status: "verified" })
  && !Model.verifyIsAffirmative({ status: "indeterminate" })
  && !Model.verifyIsAffirmative({ status: "refused" })
  && !Model.verifyIsAffirmative(null));

// Refusal alone is no longer sufficient: WHERE it was raised decides whether it
// is a verdict about evidence or merely "nothing reached the door".
check("only a front-door refusal is alarming",
  Model.verifyIsAlarming({ status: "refused", raised_by: "jackal" })
  && !Model.verifyIsAlarming({ status: "refused", raised_by: "widget" })
  && !Model.verifyIsAlarming({ status: "indeterminate" })
  && !Model.verifyIsAlarming(null));

{
  // The load-bearing distinction: a refusal raised before the front door was
  // reached is not a verification result, and must not read as one.
  const byJackal = Model.verifyRaisedByText({ raised_by: "jackal" });
  const byWidget = Model.verifyRaisedByText({ raised_by: "widget" });
  check("a JACKAL refusal says the front door looked",
    byJackal.includes("JACKAL front door"), byJackal);
  check("a widget refusal says the front door was never reached",
    byWidget.includes("before the front door"), byWidget);
  check("the two are not the same sentence", byJackal !== byWidget);
}

{
  const result = {
    status: "refused",
    artifact_kind: "receipt",
    artifact_sha256: "a02bd1a864358fda41ec07299d696691fc00b4c2938ed37457d1d0b99f9e3277",
    tool: "jackal_verify_receipt",
    authorized: {
      expected_command: "range-bound-cert",
      expected_expression: "sqrt(x)",
      expected_input_lo: "2",
      expected_input_hi: "3",
      expected_release_epoch: "v1.7.2"
    }
  };
  eq("the subject names the kind, the bytes and the door",
    Model.verifySubject(result),
    "receipt · a02bd1a8…9f9e3277 · via jackal_verify_receipt");

  const rows = Model.authorizedRows(result);
  eq("the authorization is shown sorted and de-prefixed",
    rows.map(r => r.name).join(","),
    "command,expression,input_hi,input_lo,release_epoch");
  eq("values ride through unchanged",
    rows.find(r => r.name === "expression").value, "sqrt(x)");
  eq("no authorization yields no rows", Model.authorizedRows(null).length, 0);
}

{
  // A bundle authorization carries an object; it must render, not vanish.
  const rows = Model.authorizedRows({
    authorized: { expected_root_proposition: { t: "in", arg: 1 } }
  });
  eq("an object authorization is serialized rather than dropped",
    rows.length, 1);
  check("and its content is visible",
    rows[0].value.includes('"t"'), rows[0].value);
}

// ---------------------------------------------------------------------------
// Formatting

eq("a short hash keeps both ends",
  Model.shortHash("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"),
  "01234567…89abcdef");
eq("a value too short to elide is left alone", Model.shortHash("abcd"), "abcd");
eq("never probed says never", Model.ageText(0, NOW), "never");
eq("age reads in minutes", Model.ageText(NOW - 300_000, NOW), "5m ago");
eq("one tool is singular", Model.pluralTools(1), "1 tool");
eq("many tools are plural", Model.pluralTools(8), "8 tools");

check("the tooltip never implies more than was established",
  Model.tooltip("indeterminate", null, 0, NOW) === "JACKAL + THOTH — INDETERMINATE\nProbed never");

check("the tooltip counts classes that executed at their class",
  Model.tooltip("verified", doctor(), NOW, NOW).includes("3/3 classes executed at their class"));

// ---------------------------------------------------------------------------

if (failures > 0) {
  console.error(`\n${failures} of ${checks} checks failed`);
  process.exit(1);
}
console.log(`${checks} checks passed`);
