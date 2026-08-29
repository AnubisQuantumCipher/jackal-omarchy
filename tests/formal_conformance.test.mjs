// JOP-STATE-001, JOP-STATE-002, JOP-ASSURANCE-001, JOP-CAP-001 and
// JOP-BRIDGE-001: differential conformance between the shipped JavaScript
// policy and exhaustive vectors emitted by the proved SPARK policy kernel.

import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const source = readFileSync(join(root, "Model.js"), "utf8");
const vectorBinary = join(root, "formal", "bin", "jackal_assurance_vectors");

const exported = [
  "classify",
  "assuranceCeiling",
  "consequenceCapsAssurance"
];

const Model = new Function(
  `${source.replace(/^\.pragma library\s*/, "")}\nreturn {${exported.join(",")}};`
)();

const run = spawnSync(vectorBinary, [], {
  encoding: "utf8",
  maxBuffer: 8 * 1024 * 1024
});

if (run.error) throw run.error;
if (run.status !== 0) {
  throw new Error(`SPARK vector emitter failed: ${run.stderr}`);
}

const mathStatuses = [
  "estimated", "model-based", "checked", "bounded", "formal-bounded", "exact"
];
const consequences = [
  "informational", "advisory", "decision-boundary", "safety-critical"
];
const verificationMap = {
  VERIFICATION_NOT_RUN: null,
  VERIFICATION_PASS: { verify: "PASS" },
  VERIFICATION_FAIL: { verify: "FAIL" }
};
const doctorMap = {
  DOCTOR_INDETERMINATE: "INDETERMINATE",
  DOCTOR_FUNCTIONAL: "FUNCTIONAL",
  DOCTOR_DEGRADED: "DEGRADED",
  DOCTOR_REFUSED: "REFUSED",
  DOCTOR_NOT_INSTALLED: "NOT_INSTALLED"
};

const now = 1_700_000_000_000;
const staleAfter = 2_400;
const failures = [];
const observed = { STATE: 0, ASSURANCE: 0, CAP: 0 };

function flag(mask, position) {
  return Math.floor(mask / (2 ** position)) % 2 === 1;
}

function fromMask(mask, values) {
  return values.filter((_value, position) => flag(mask, position));
}

function normalizeAda(value) {
  return value.trim().toLowerCase().replaceAll("_", "-");
}

for (const rawLine of run.stdout.trim().split("\n")) {
  const fields = rawLine.split("|").map(field => field.trim());
  const kind = fields[0];
  if (kind === "DOCTOR") continue;
  if (!(kind in observed)) {
    failures.push(`unknown vector kind: ${rawLine}`);
    continue;
  }
  observed[kind] += 1;

  if (kind === "STATE") {
    const mask = Number(fields[1]);
    const verification = verificationMap[fields[2]];
    const doctor = doctorMap[fields[3]];
    const expected = normalizeAda(fields[4]);
    const reportPresent = flag(mask, 0);
    const report = reportPresent ? {
      error: flag(mask, 1) ? "test-error" : "",
      installed: flag(mask, 2),
      identity_match: flag(mask, 3),
      receivedAtMs: flag(mask, 4) ? now - (staleAfter + 1) * 1000 : now,
      function: flag(mask, 5) ? {
        exact: { functional_pass: flag(mask, 6) }
      } : {},
      doctor_verdict: doctor
    } : null;
    const actual = Model.classify(report, verification, now, staleAfter);
    if (actual !== expected) {
      failures.push(`STATE mask=${mask} verify=${fields[2]} doctor=${fields[3]} expected=${expected} actual=${actual}`);
    }
  } else if (kind === "ASSURANCE") {
    const mask = Number(fields[1]);
    const present = fields[2] === "TRUE";
    const expected = present ? normalizeAda(fields[3]) : "";
    const actual = Model.assuranceCeiling(fromMask(mask, mathStatuses));
    if (actual !== expected) {
      failures.push(`ASSURANCE mask=${mask} expected=${expected} actual=${actual}`);
    }
  } else {
    const assuranceMask = Number(fields[1]);
    const consequenceMask = Number(fields[2]);
    const carriesAxis = fields[3] === "TRUE";
    const expected = fields[4] === "TRUE";
    const actual = Model.consequenceCapsAssurance(
      fromMask(assuranceMask, mathStatuses),
      fromMask(consequenceMask, consequences),
      carriesAxis
    );
    if (actual !== expected) {
      failures.push(`CAP assurance=${assuranceMask} consequence=${consequenceMask} carriesAxis=${carriesAxis} expected=${expected} actual=${actual}`);
    }
  }
}

// The JavaScript age calculation is outside the SPARK Boolean abstraction.
// Lock its exact boundary separately: equality is fresh; only greater is stale.
{
  const report = {
    installed: true,
    identity_match: true,
    receivedAtMs: now - staleAfter * 1000,
    function: { exact: { functional_pass: true } },
    doctor_verdict: "FUNCTIONAL"
  };
  const state = Model.classify(report, null, now, staleAfter);
  if (state !== "verified") failures.push(`staleness equality boundary expected=verified actual=${state}`);
}

if (Object.values(observed).some(count => count === 0)) {
  failures.push(`missing vector class: ${JSON.stringify(observed)}`);
}

if (failures.length > 0) {
  for (const failure of failures.slice(0, 40)) console.error(`FAIL ${failure}`);
  if (failures.length > 40) console.error(`FAIL ${failures.length - 40} additional mismatches`);
  process.exit(1);
}

console.log(`SPARK_JS_CONFORMANCE_PASS state=${observed.STATE} assurance=${observed.ASSURANCE} cap=${observed.CAP}`);
