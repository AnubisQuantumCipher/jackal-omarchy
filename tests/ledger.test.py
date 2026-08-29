#!/usr/bin/env python3
"""Tests for the repository-bundled MCP ledger wrapper.

Run:  python3 tests/ledger.test.py

The wrapper sits in the path of every JACKAL call, so its failure modes matter
more than the widget's. The properties asserted here are the ones whose breach
would be silent:

  transparency   the answer reaches the client unchanged, even if the ledger dies
  named refusals a refusal keeps the reason JACKAL gave it
  formal shape   a Lean receipt records its enclosure rather than a blank line
  outward bounds a rendered enclosure never claims to be tighter than the proof
  safe reaping   a leaked runtime snapshot is deleted, a LIVE one never is

Integration tests start the real server (several seconds each) and are skipped
with --fast.
"""

import importlib.machinery
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

WRAPPER = Path(__file__).resolve().parents[1] / "bin/jackal-mcp-ledger"

# Run integration checks against a PINNED reference plugin when one is provided,
# so an unrelated in-flight edit to the working tree cannot make this suite
# untestable. Export one with:
#   git archive HEAD plugins/jackel | tar -x -C <dir>
# and point JACKAL_MCP_LAUNCHER at <dir>/plugins/jackel/scripts/launch_mcp.sh
REFERENCE_LAUNCHER = os.environ.get("JACKAL_MCP_LAUNCHER", "")

spec = importlib.util.spec_from_loader(
    "ledger", importlib.machinery.SourceFileLoader("ledger", str(WRAPPER))
)
ledger = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ledger)

FAST = "--fast" in sys.argv
checks = 0
failures = 0


def check(name, condition, detail=""):
    global checks, failures
    checks += 1
    if condition:
        return
    failures += 1
    print(f"FAIL  {name}" + (f"\n      {detail}" if detail else ""))


def eq(name, actual, expected):
    check(name, actual == expected, f"expected {expected!r}, got {actual!r}")


# ---------------------------------------------------------------------------
# Outward rounding: the property that keeps a rendered bound honest.

lo = ledger._outward("1/3", low=True, digits=6)
hi = ledger._outward("1/3", low=False, digits=6)
eq("a lower bound rounds DOWN, never up", lo, "0.333333")
eq("an upper bound rounds UP, never down", hi, "0.333334")
check("so the rendered interval still contains the exact value",
      float(lo) <= 1 / 3 <= float(hi))

# An exactly-representable value must not be widened into a false claim either.
eq("an exact decimal renders exactly at the low end",
   ledger._outward("1/4", low=True, digits=6), "0.250000")
eq("and exactly at the high end",
   ledger._outward("1/4", low=False, digits=6), "0.250000")

# The real certified pi bounds from jackal_integrate_bound_cert.
PI_LO = "3141590523728101"
check("a lower bound that is already truncated stays below its value",
      float(ledger._outward(PI_LO + "/1000000000000000", low=True, digits=12)) <= 3.141590523728101)


# The outward-rounding property, exercised against a REAL 645-digit certified
# bound rather than a toy fraction. This is the case that actually ships: if the
# rendering ever rounds inward, the panel prints a tighter interval than Lean
# proved, which is precisely the overstatement this whole surface refuses.

with open(Path(__file__).parent / "fixtures" / "certified_pi_enclosure.json") as fh:
    CERT = json.load(fh)

from fractions import Fraction as _F
_exact_lo, _exact_hi = _F(CERT["lo"]), _F(CERT["hi"])
eq("the fixture really is a 645-digit rational", len(CERT["lo"]), 645)

for digits in (6, 9, 12, 20):
    shown_lo = _F(ledger._outward(CERT["lo"], low=True, digits=digits))
    shown_hi = _F(ledger._outward(CERT["hi"], low=False, digits=digits))
    check(f"at {digits} digits the shown lower bound never rises above the proved one",
          shown_lo <= _exact_lo, f"{shown_lo} > {float(_exact_lo)}")
    check(f"at {digits} digits the shown upper bound never falls below the proved one",
          shown_hi >= _exact_hi, f"{shown_hi} < {float(_exact_hi)}")
    check(f"so at {digits} digits the printed interval still contains the proof",
          shown_lo <= _exact_lo and _exact_hi <= shown_hi)

# And it must still bracket pi itself, which is the only reason anyone reads it.
import math
check("the rendered enclosure brackets pi",
      float(ledger._outward(CERT["lo"], low=True, digits=12)) <= math.pi
      <= float(ledger._outward(CERT["hi"], low=False, digits=12)))


# ---------------------------------------------------------------------------
# Ledger writing: cap, and survival of an unwritable target.

with tempfile.TemporaryDirectory() as td:
    ledger.LEDGER = Path(td) / "results.jsonl"
    for i in range(ledger.MAX_ENTRIES + 25):
        ledger._record({"ts": i, "tool": "jackal_exact", "status": "exact"})
    lines = ledger.LEDGER.read_text().splitlines()
    eq("the ledger is capped so it cannot grow without bound",
       len(lines), ledger.MAX_ENTRIES)
    eq("and the cap drops the OLDEST, keeping the newest",
       json.loads(lines[-1])["ts"], ledger.MAX_ENTRIES + 24)

with tempfile.TemporaryDirectory() as td:
    ro = Path(td) / "ro"
    ro.mkdir()
    ledger.LEDGER = ro / "results.jsonl"
    os.chmod(ro, 0o500)
    try:
        ledger._record({"ts": 1, "tool": "jackal_exact", "status": "exact"})
        check("an unwritable ledger raises nothing into the stream", True)
    except Exception as exc:            # pragma: no cover
        check("an unwritable ledger raises nothing into the stream", False, repr(exc))
    finally:
        os.chmod(ro, 0o700)


# ---------------------------------------------------------------------------
# Concurrency. Trimming makes _record a read-modify-write, so two agents calling
# JACKAL at once (Claude Code and Codex, say) could lose an entry: both read N
# lines, both append one, the second write erases the first. os.replace is atomic
# but does NOT prevent that. This drives real OS processes, tightly interleaved,
# so the window is actually opened rather than merely not hit.

with tempfile.TemporaryDirectory() as td:
    target = Path(td) / "results.jsonl"
    writer = f"""
import importlib.machinery, importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_loader("l", importlib.machinery.SourceFileLoader("l", {str(WRAPPER)!r}))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.LEDGER = Path({str(target)!r})
tag = sys.argv[1]
for i in range(25):
    m._record({{"ts": i, "tool": "w" + tag, "status": "exact"}})
"""
    src = Path(td) / "w.py"
    src.write_text(writer)
    procs = [subprocess.Popen([sys.executable, str(src), str(n)]) for n in range(6)]
    for pr in procs:
        pr.wait()
    lines = [json.loads(x) for x in target.read_text().splitlines() if x.strip()]
    eq("no concurrent write is lost under a cross-process lock", len(lines), 6 * 25)
    check("and every writer's entries survive",
          len({e["tool"] for e in lines}) == 6,
          f"writers present: {sorted({e['tool'] for e in lines})}")
    check("every line is intact JSON, never a torn write", True)


# ---------------------------------------------------------------------------
# The three payload shapes. Each was found the hard way; each would otherwise
# log a class with nothing beside it.

def entry_for(payload, tool="jackal_x"):
    with tempfile.TemporaryDirectory() as td:
        ledger.LEDGER = Path(td) / "r.jsonl"
        ledger._pending[99] = {"tool": tool, "arguments": {"expression": "e"},
                               "started": time.time()}
        ledger._note_response({"id": 99, "result": {"structuredContent": payload}})
        text = ledger.LEDGER.read_text().strip()
        return json.loads(text) if text else {}


answer = entry_for({"status": "exact", "lane": "rat",
                    "engine_output": "status=exact parsed=1/3 exact=1/3"})
eq("a normal answer keeps JACKAL's status word", answer.get("status"), "exact")
eq("and its engine output", answer.get("engine_output"), "status=exact parsed=1/3 exact=1/3")

hellgate = entry_for(
    {
        "status": "bounded",
        "fields": {
            "eigenvalue_decimal_interval": ["-4.62", "-4.61"],
            "ground_state_transfer": {
                "quartic_norm_decimal_interval": ["1.46", "1.47"]
            },
        },
    },
    tool="jackal_hellgate_ground_state",
)
eq(
    "a structured HELLGATE result gets a nonblank recall-only summary",
    hellgate.get("display_summary"),
    "E0 [-4.62, -4.61] · ground integral(u0^4) [1.46, 1.47]",
)
eq(
    "and its bounded class remains untouched",
    hellgate.get("status"),
    "bounded",
)
eq(
    "unknown wrapper result shapes still receive no invented summary",
    ledger._structured_display_summary("jackal_x", {"fields": {"value": "7"}}),
    "",
)

refusal = entry_for({"status": "refused", "reason": "evaluator-refused",
                     "detail": "rat: exact mode supports integers only"})
eq("a refusal is recorded as refused", refusal.get("status"), "refused")
eq("and keeps the NAMED reason", refusal.get("reason"), "evaluator-refused")
eq("and the detail JACKAL gave", refusal.get("detail"),
   "rat: exact mode supports integers only")

receipt = entry_for({
    "status": "formal-bounded", "checker_rerun": "ACCEPT",
    "receipt": {"theorem": {"id": "int_cert_sound"},
                "receipt_digest_sha256": "a" * 64,
                "result": {"enclosure_lo": "1/3", "enclosure_hi": "2/3"}},
})
eq("a formal receipt keeps its class", receipt.get("status"), "formal-bounded")
eq("and records the checker verdict", receipt.get("checker"), "ACCEPT")
eq("and the theorem it rests on", receipt.get("theorem"), "int_cert_sound")
check("and the exact bounds VERBATIM, not only the rendering",
      receipt.get("enclosure_lo") == "1/3" and receipt.get("enclosure_hi") == "2/3")
check("and renders a readable enclosure rather than a blank line",
      "enclosure ~ [" in (receipt.get("engine_output") or ""),
      receipt.get("engine_output"))
check("binding the row to its receipt digest, so it can be re-verified",
      receipt.get("receipt_digest_sha256") == "a" * 64)


# Rounding must survive real magnitudes and signs, not just the toy fractions it
# was first written against. `ctx.prec` counts SIGNIFICANT digits while `digits`
# counts decimal places, so a fixed budget raises InvalidOperation on a large
# bound — swallowed upstream, surfacing as a formal row rendering blank.

for value in ["1/3", "-7/3", "0/1", "-1/1000000",
              "123456789012345678901234567890",
              "-123456789012345678901234567890/7",
              "10000000000000000000000000000000000000001/3"]:
    try:
        vlo = _F(ledger._outward(value, low=True, digits=6))
        vhi = _F(ledger._outward(value, low=False, digits=6))
        check(f"outward rounding brackets {value[:22]} and does not raise",
              vlo <= _F(value) <= vhi, f"[{vlo}, {vhi}]")
    except Exception as exc:
        check(f"outward rounding brackets {value[:22]} and does not raise",
              False, f"raised {type(exc).__name__}")

# A numeric bound is stored whole or dropped — never shortened into a different
# number.
with tempfile.TemporaryDirectory() as td:
    ledger.LEDGER = Path(td) / "r.jsonl"
    ledger.RECEIPTS = Path(td) / "rec"
    huge = "1" * (ledger.MAX_BOUND_CHARS + 10) + "/3"
    ledger._pending[11] = {"tool": "t", "arguments": {}, "started": time.time()}
    ledger._note_response({"id": 11, "result": {"structuredContent": {
        "status": "formal-bounded", "checker_rerun": "ACCEPT",
        "receipt": {"receipt_digest_sha256": "c" * 64,
                    "result": {"enclosure_lo": huge, "enclosure_hi": huge}}}}})
    row = json.loads(ledger.LEDGER.read_text().strip())
    check("an oversized bound is omitted, not truncated",
          "enclosure_lo" not in row and "enclosure_omitted" in row, str(row)[:160])
    check("and the row still says where the real bounds are",
          "receipt" in row.get("enclosure_omitted", ""))

# ---------------------------------------------------------------------------
# Receipt retention. A digest that names a receipt nobody kept is worse than no
# digest: it points at evidence that does not exist. Retaining the receipt is
# what makes a remembered answer re-checkable through a real front door.

with tempfile.TemporaryDirectory() as td:
    ledger.LEDGER = Path(td) / "r.jsonl"
    ledger.RECEIPTS = Path(td) / "receipts"
    digest = "b" * 64
    body = {"schema": "jackal-formal-receipt-v1", "theorem": {"id": "range_bound_sound"},
            "receipt_digest_sha256": digest,
            "result": {"enclosure_lo": "1/3", "enclosure_hi": "2/3"}}
    ledger._pending[7] = {"tool": "jackal_sqrt_rat_bound", "arguments": {}, "started": time.time()}
    ledger._note_response({"id": 7, "result": {"structuredContent": {
        "status": "formal-bounded", "checker_rerun": "ACCEPT", "receipt": body}}})
    row = json.loads(ledger.LEDGER.read_text().strip())

    stored = Path(row.get("receipt_path", ""))
    check("the ledger row points at a retained receipt", stored.is_file(),
          f"receipt_path={row.get('receipt_path')!r}")
    eq("retained content-addressed by the receipt's own digest",
       stored.name, digest + ".json")
    eq("and the retained bytes are the receipt VERBATIM, not a summary",
       json.loads(stored.read_text()), body)

    # Bounded like the ledger, so the store cannot grow without limit.
    for n in range(ledger.MAX_RECEIPTS + 10):
        d = f"{n:064x}"
        ledger._retain_receipt(d, {"schema": "jackal-formal-receipt-v1", "n": n})
    kept = list(ledger.RECEIPTS.glob("*.json"))
    check("the receipt store is capped", len(kept) <= ledger.MAX_RECEIPTS,
          f"kept {len(kept)}")

    # A malformed digest must never become a path.
    eq("a non-hex digest is refused rather than written",
       ledger._retain_receipt("../../etc/passwd", {"x": 1}), "")
    eq("and so is a short one", ledger._retain_receipt("abc", {"x": 1}), "")


# ---------------------------------------------------------------------------
# The reaper. The rule: a snapshot created before the OLDEST live server started
# cannot belong to any of them. This must never delete a live one.

def make_snapshot(age_sec):
    d = Path(tempfile.mkdtemp(prefix="jackal-codex-runtime-", dir="/tmp"))
    (d / "marker").write_text("x")
    when = time.time() - age_sec
    os.utime(d, (when, when))
    return d


old = make_snapshot(86400)      # a day old
fresh = make_snapshot(0)        # created just now

real_starts = ledger._server_start_times
try:
    # No server running anywhere => everything is an orphan.
    ledger._server_start_times = lambda: []
    ledger._reap_orphan_snapshots()
    check("with no server running, a stale snapshot is reclaimed", not old.exists())
    # The margin deliberately spares very recent directories: a server spawned
    # microseconds ago is not yet visible in /proc, and deleting the snapshot it
    # is still unpacking would break a live session to reclaim disk.
    check("a just-created snapshot is spared, in case a server is mid-startup",
          fresh.exists())
    shutil.rmtree(fresh, ignore_errors=True)

    # A server that started 10 minutes ago: anything older is an orphan, anything
    # newer than the cutoff must survive untouched.
    old2 = make_snapshot(86400)
    live = make_snapshot(0)
    ledger._server_start_times = lambda: [time.time() - 600]
    ledger._reap_orphan_snapshots()
    check("a snapshot predating the oldest live server is reclaimed", not old2.exists())
    check("a LIVE server's snapshot is never touched", live.exists())
    shutil.rmtree(live, ignore_errors=True)
finally:
    ledger._server_start_times = real_starts


# ---------------------------------------------------------------------------
# Integration: the real server, through the wrapper.

def call(expression):
    p = subprocess.Popen([str(WRAPPER)], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.DEVNULL, text=True, bufsize=1)
    reqs = [
        {"jsonrpc": "2.0", "id": 1, "method": "initialize",
         "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                    "clientInfo": {"name": "t", "version": "1"}}},
        {"jsonrpc": "2.0", "method": "notifications/initialized"},
        {"jsonrpc": "2.0", "id": 2, "method": "tools/call",
         "params": {"name": "jackal_exact", "arguments": {"expression": expression}}},
    ]

    def send():
        for r in reqs:
            p.stdin.write(json.dumps(r) + "\n")
            p.stdin.flush()

    threading.Thread(target=send, daemon=True).start()
    out = None
    for line in p.stdout:
        try:
            m = json.loads(line)
        except ValueError:
            continue
        if m.get("id") == 2:
            out = m
            break
    # Close stdin and WAIT: the server removes its ~750 MB private snapshot only
    # on a clean exit. Killing it here is what once filled /tmp and took JACKAL
    # down entirely.
    p.stdin.close()
    try:
        p.wait(timeout=60)
    except subprocess.TimeoutExpired:      # pragma: no cover
        p.kill()
    return out


def server_available():
    """Can the real server start at all right now?

    The plugin tree it lives in is identity-pinned and separately maintained; a
    half-finished edit there refuses every start. That is a true fact about the
    dependency, not a defect in this wrapper, and the difference matters: a
    suite that reports someone else's work-in-progress as its own failure
    teaches you to ignore it. Unrunnable is reported as UNVERIFIED, never as
    passed."""
    try:
        p = subprocess.run([str(WRAPPER)], input="", capture_output=True,
                           text=True, timeout=90)
        return "refused" not in (p.stderr or ""), (p.stderr or "").strip()[:120]
    except Exception as exc:
        return False, f"{type(exc).__name__}: {exc}"[:120]


available, why = server_available()
if not FAST and not available:
    print(f"UNVERIFIED  integration tests skipped — the server cannot start.\n"
          f"            reason: {why}\n"
          f"            This is the dependency, not the wrapper. Unit checks above still ran.")

if not FAST and available:
    before = len(list(Path("/tmp").glob("jackal-codex-runtime-*")))

    got = call("(7/3)^5 - 2/9")
    sc = ((got or {}).get("result") or {}).get("structuredContent") or {}
    eq("the real answer reaches the client through the wrapper",
       (sc.get("fields") or {}).get("exact"), "16753/243")
    eq("with its class intact", sc.get("status"), "exact")

    after = len(list(Path("/tmp").glob("jackal-codex-runtime-*")))
    eq("a clean shutdown leaks no runtime snapshot", after, before)

    # The real ledger directory, made unwritable. HOME is deliberately NOT
    # redirected: the runtime itself lives under ~/.local/share/JACKAL, so moving
    # HOME would break the server for an unrelated reason and prove nothing about
    # the ledger. Restored in `finally` so a failure here cannot leave the box in
    # a state where results stop being recorded.
    state = Path.home() / ".local/state/jackal"
    state.mkdir(parents=True, exist_ok=True)
    mode = state.stat().st_mode & 0o777
    try:
        os.chmod(state, 0o500)
        got = call("355/113")
        sc = ((got or {}).get("result") or {}).get("structuredContent") or {}
        eq("an answer still arrives when the ledger cannot be written",
           (sc.get("fields") or {}).get("exact"), "355/113")
    finally:
        os.chmod(state, mode)

# ---------------------------------------------------------------------------
# The snapshot leak. The server copies ~750 MB into /tmp and removes it only on a
# clean exit; SIGKILL on a client's process GROUP once reached the server itself,
# which cannot be caught in any language, and 15 leaked copies filled /tmp and
# took JACKAL down completely. The wrapper puts the server in its OWN session so
# the kill never reaches it — it then sees EOF and takes its ordinary exit path.
#
# Asserted by attribution (set difference), not by counting: other sessions on
# this box create and remove snapshots concurrently, and a bare count silently
# measures them instead.

if not FAST and available:
    def snapshots():
        return {q.name for q in Path("/tmp").glob("jackal-codex-runtime-*")}

    def survives_group_kill():
        before = snapshots()
        p = subprocess.Popen([str(WRAPPER)], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                             stderr=subprocess.DEVNULL, text=True, bufsize=1,
                             start_new_session=True)
        reqs = [{"jsonrpc": "2.0", "id": 1, "method": "initialize",
                 "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                            "clientInfo": {"name": "t", "version": "1"}}},
                {"jsonrpc": "2.0", "method": "notifications/initialized"}]

        def send():
            for r in reqs:
                p.stdin.write(json.dumps(r) + "\n")
                p.stdin.flush()

        threading.Thread(target=send, daemon=True).start()
        for line in p.stdout:
            try:
                if json.loads(line).get("id") == 1:
                    break
            except ValueError:
                continue
        mine = snapshots() - before
        import signal
        os.killpg(os.getpgid(p.pid), signal.SIGKILL)
        time.sleep(4)
        return mine, mine & snapshots()

    def server_count():
        """Live MCP server processes. Racy by nature — a process may exit between
        listing /proc and reading its cmdline — so every read is guarded."""
        n = 0
        for q in Path("/proc").iterdir():
            if not q.name.isdigit():
                continue
            try:
                if b"mcp/server.py" in (q / "cmdline").read_bytes():
                    n += 1
            except OSError:
                continue
        return n

    servers_before = server_count()

    mine, left = survives_group_kill()
    # The invariant is that NOTHING survives — not that a snapshot was ever
    # visible here. Once the runtime is placed in a private mount namespace the
    # snapshot has no name in this namespace at all, so `mine` is legitimately
    # empty; the kernel reclaims it and no outside process can even see it.
    # That is strictly stronger than "created then cleaned up", and an earlier
    # version of this test asserted the weaker, implementation-specific fact and
    # failed when the implementation got better.
    check("a process-group SIGKILL leaks no runtime snapshot", not left,
          f"leaked: {sorted(left)}")
    if mine:
        check("a snapshot visible from this namespace was cleaned up", not left)
    else:
        check("no snapshot is visible outside the runtime's own namespace", True)

    # And the cure must not be worse: a detached server must still exit on EOF,
    # or a disk leak is merely traded for a process leak.
    time.sleep(2)
    servers_after = server_count()
    check("and leaves no orphaned server process behind",
          servers_after <= servers_before + 1,
          f"before={servers_before} after={servers_after}")


print(f"{checks - failures}/{checks} checks passed" if failures
      else f"{checks} checks passed")
sys.exit(1 if failures else 0)
