#!/usr/bin/env python3
"""Route one clipboard artifact through a JACKAL verification front door.

This script is a ROUTER and a REFUSER. It performs no mathematics, checks no
certificate, and mints no assurance. Every verdict it reports comes verbatim
from `jackal_verify_receipt` / `jackal_verify_bundle`, which are the real front
doors; this file only decides which one to call, supplies the operator's
authorization, and refuses when it cannot.

THE LOAD-BEARING RULE
=====================
`plugins/jackel/skills/jackel/SKILL.md`:

    Verification expectations are authorization, not data discovery. Expected
    bundle and receipt values must come from the caller or separately trusted
    source, not evidence under review. Never copy an `expected_*` value from
    the bundle or receipt being verified.

A verifier fed expectations taken from the artifact under review will always
pass, and the pass means nothing. So this script keeps the two apart
structurally, not by intention: `build_args()` receives ONLY the operator's
expectations dict. The parsed artifact is never in its scope, so there is no
place from which an expectation could be copied even by mistake.

Routing is a separate question from authorization and is allowed to read the
artifact's declared `schema` and certificate schema — that decides WHICH front
door and WHICH argument set, never WHAT VALUE is authorized.

Consequence of the rule, stated plainly because it will look like a bug: the
expectations file authorizes ONE request. A receipt for anything else refuses.
That is correct. "This is not what you authorized" is the honest answer, and
widening the authorization is an explicit operator edit.

Refusal classes raised HERE are prefixed `widget-` so they can never be mistaken
for one of JACKAL's own. Everything else passes through untouched.

Usage:  verify_artifact.py --runtime <dir> --expectations <file>
                           [--artifact-file <path>]   # default: clipboard
Output: exactly one JSON object on stdout. Exit 0 verified, 1 refused,
        3 indeterminate, 2 usage.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import subprocess
import sys
from pathlib import Path

SCHEMA = "khephri.jackal-verify-v1"
EXPECTATIONS_SCHEMA = "khephri.jackal-expectations-v1"

RECEIPT_SCHEMA = "jackal-formal-receipt-v1"
BUNDLE_SCHEMA = "jackal-claim-bundle-v1"

# Certificate schemas whose lane is tolerance-bearing. Reading this from the
# artifact is ROUTING (which argument set), not discovery (what value).
TOLERANCE_CERT_SCHEMAS = {
    "jackal-gaussian-integral-cert v1",
    "jackal-int-cert v1",
}

RECEIPT_REQUIRED = [
    "expected_release_epoch",
    "expected_command",
    "expected_expression",
    "expected_input_lo",
    "expected_input_hi",
]
RECEIPT_OPTIONAL = ["expected_tolerance"]

BUNDLE_REQUIRED = [
    "expected_release_epoch",
    "expected_policy_sha256",
    "expected_root_proposition",
]
BUNDLE_OPTIONAL = ["expected_nonce"]

# A real jackal-formal-receipt-v1 from `integrate-bound-cert` measured 8.77 MB on
# this box: the embedded certificate carries the whole subdivision tree as exact
# rationals, and the strongest lane is therefore the largest artifact. The old
# 4 MiB cap silently refused exactly those receipts with `widget-artifact-oversize`
# — the one class of evidence most worth checking was the one that could not be.
# The cap still exists to bound memory; it is now set above measured reality
# rather than below it.
MAX_ARTIFACT_BYTES = 64 * 1024 * 1024
MAX_EXPECTATIONS_BYTES = 1024 * 1024


class Refusal(Exception):
    """A refusal raised by this router, never by a front door."""

    def __init__(self, reason: str, detail: str = "") -> None:
        super().__init__(detail)
        self.reason = reason
        self.detail = detail


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def strict_json(raw: str, what: str, reason: str):
    """Parse JSON with duplicate keys refused, like every JACKAL boundary."""

    def no_duplicates(pairs):
        out = {}
        for key, value in pairs:
            if key in out:
                raise ValueError(f"duplicate key: {key}")
            out[key] = value
        return out

    try:
        return json.loads(raw, object_pairs_hook=no_duplicates)
    except (ValueError, RecursionError) as exc:
        raise Refusal(reason, f"{what}: {exc}") from None


# --------------------------------------------------------------------------
# The operator's authorization


def load_expectations(path: Path) -> dict:
    """Read the operator-owned authorization file.

    Absent is a refusal with its own class, not an empty default: a widget that
    silently proceeded with no authorization would be asserting one.
    """
    try:
        info = path.lstat()
        if path.is_symlink() or not stat.S_ISREG(info.st_mode):
            raise Refusal(
                "widget-expectations-unreadable",
                "authorization path is not a regular non-symlink file",
            )
        if info.st_size < 1 or info.st_size > MAX_EXPECTATIONS_BYTES:
            raise Refusal(
                "widget-expectations-oversize",
                f"authorization size is outside 1..{MAX_EXPECTATIONS_BYTES} bytes",
            )
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise Refusal(
            "widget-expectations-absent",
            f"no authorization file at {path}; write one before verifying",
        ) from None
    except OSError as exc:
        raise Refusal("widget-expectations-unreadable", str(exc)) from None

    doc = strict_json(raw, str(path), "widget-expectations-malformed")
    if not isinstance(doc, dict):
        raise Refusal("widget-expectations-malformed", "not a JSON object")
    if doc.get("schema") != EXPECTATIONS_SCHEMA:
        raise Refusal(
            "widget-expectations-malformed",
            f"schema is {doc.get('schema')!r}, expected {EXPECTATIONS_SCHEMA!r}",
        )
    return doc


def lane_expectations(doc: dict, lane: str, required: list[str],
                      optional: list[str], needs: list[str]) -> dict:
    """Extract exactly the authorized keys for one lane.

    Returns a NEW dict built only from the expectations document. This is the
    structural guarantee: the artifact is not a parameter here.
    """
    section = doc.get(lane)
    if not isinstance(section, dict):
        raise Refusal(
            "widget-expectations-missing-lane",
            f"the authorization file declares no {lane!r} section",
        )

    wanted = list(required) + [k for k in optional if k in needs]
    missing = [k for k in wanted if k not in section]
    if missing:
        raise Refusal(
            "widget-expectations-incomplete",
            f"{lane}: missing {', '.join(missing)}",
        )

    extra = set(section) - set(required) - set(optional)
    if extra:
        raise Refusal(
            "widget-expectations-incomplete",
            f"{lane}: unknown key(s) {', '.join(sorted(extra))}",
        )

    authorized = {}
    for key in wanted:
        value = section[key]
        if key == "expected_root_proposition":
            if not isinstance(value, dict):
                raise Refusal("widget-expectations-incomplete",
                              f"{lane}: {key} must be an object")
        elif not isinstance(value, str) or not value:
            raise Refusal("widget-expectations-incomplete",
                          f"{lane}: {key} must be a non-empty string")
        authorized[key] = value
    return authorized


# --------------------------------------------------------------------------
# The artifact under review


def read_clipboard() -> str:
    try:
        proc = subprocess.run(["wl-paste", "--no-newline"],
                              capture_output=True, timeout=10)
    except FileNotFoundError:
        raise Refusal("widget-clipboard-unavailable", "wl-paste is not on PATH") from None
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise Refusal("widget-clipboard-unavailable", str(exc)) from None
    if proc.returncode != 0:
        raise Refusal("widget-clipboard-empty",
                      (proc.stderr or b"").decode("utf-8", "replace").strip()[:200])
    if len(proc.stdout) > MAX_ARTIFACT_BYTES:
        raise Refusal("widget-artifact-oversize",
                      f"{len(proc.stdout)} bytes exceeds {MAX_ARTIFACT_BYTES}")
    text = proc.stdout.decode("utf-8", "replace").strip()
    if not text:
        raise Refusal("widget-clipboard-empty", "the clipboard holds no text")
    return text


def read_artifact_file(path: Path) -> str:
    """Read an artifact from a file instead of the clipboard.

    Same artifact, same front door, same authorization — only the transport
    differs. This exists so a receipt RETAINED from an earlier call can be
    re-verified later, which the clipboard cannot do.

    It changes nothing about the load-bearing rule. The expectations still come
    from the operator's file and are still read first; this function returns
    bytes and has no access to them. A retained receipt is evidence under
    review exactly like a pasted one, and is trusted exactly as little.
    """
    try:
        info = path.lstat()
        if path.is_symlink() or not stat.S_ISREG(info.st_mode):
            raise Refusal(
                "widget-artifact-unreadable",
                "artifact path is not a regular non-symlink file",
            )
        if info.st_size > MAX_ARTIFACT_BYTES:
            raise Refusal("widget-artifact-oversize",
                          f"{info.st_size} bytes exceeds {MAX_ARTIFACT_BYTES}")
        raw = path.read_bytes()
    except OSError as exc:
        raise Refusal("widget-artifact-unreadable", str(exc)[:200]) from None
    if len(raw) > MAX_ARTIFACT_BYTES:
        raise Refusal("widget-artifact-oversize",
                      f"{len(raw)} bytes exceeds {MAX_ARTIFACT_BYTES}")
    text = raw.decode("utf-8", "replace").strip()
    if not text:
        raise Refusal("widget-artifact-empty", f"{path} holds no text")
    return text


def classify_artifact(text: str) -> tuple[str, dict, list[str]]:
    """Route on the artifact's DECLARED schema. Returns (kind, doc, needs).

    `needs` names optional expectation keys this artifact's lane requires. It is
    derived from the artifact's certificate schema, which is a routing fact, not
    an authorized value.
    """
    doc = strict_json(text, "clipboard", "widget-clipboard-not-json")
    if not isinstance(doc, dict):
        raise Refusal("widget-artifact-unrecognised", "not a JSON object")

    schema = doc.get("schema")
    if schema == RECEIPT_SCHEMA:
        cert_schema = (doc.get("certificate") or {}).get("schema")
        needs = ["expected_tolerance"] if cert_schema in TOLERANCE_CERT_SCHEMAS else []
        return "receipt", doc, needs
    if schema == BUNDLE_SCHEMA:
        return "bundle", doc, []
    raise Refusal(
        "widget-artifact-unrecognised",
        f"schema {schema!r} is neither {RECEIPT_SCHEMA} nor {BUNDLE_SCHEMA}",
    )


# --------------------------------------------------------------------------
# The front door


def build_args(kind: str, artifact_key: str, artifact, authorized: dict,
               now_unix: str) -> dict:
    """Assemble the tool arguments.

    `authorized` is the ONLY source of `expected_*` values. The artifact rides
    as the payload under its own key and is never read here.
    """
    args = {artifact_key: artifact}
    args.update(authorized)
    if kind == "bundle":
        # Not an authorization — the wall clock, for the verifier's own
        # freshness and expiry checks.
        args["verification_time_unix"] = now_unix
    return args


def run_front_door(runtime: Path, tool: str, args: dict, timeout: int) -> dict:
    launcher = runtime / "plugin" / "hermes" / "jackal_hermes"
    try:
        launcher_info = launcher.lstat()
    except OSError:
        launcher_info = None
    if (
        launcher_info is None
        or launcher.is_symlink()
        or not stat.S_ISREG(launcher_info.st_mode)
        or not os.access(launcher, os.X_OK)
    ):
        raise Refusal("widget-runtime-absent", f"no launcher at {launcher}")
    try:
        proc = subprocess.run(
            [str(launcher), "call", tool, json.dumps(args, sort_keys=True)],
            capture_output=True, text=True, timeout=timeout, cwd=str(runtime),
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise Refusal("widget-front-door-failed", f"{type(exc).__name__}: {exc}") from None

    stdout = (proc.stdout or "").strip()
    if not stdout:
        raise Refusal(
            "widget-front-door-unparsable",
            (proc.stderr or "").strip()[:300] or "the front door emitted nothing",
        )
    try:
        result = json.loads(stdout)
    except ValueError:
        raise Refusal("widget-front-door-unparsable", stdout[:300]) from None
    if not isinstance(result, dict) or "status" not in result:
        raise Refusal("widget-front-door-unparsable", "no status field")
    return result


# --------------------------------------------------------------------------

EXIT = {"verified": 0, "refused": 1, "indeterminate": 3}


def emit(payload: dict) -> int:
    payload["schema"] = SCHEMA
    print(json.dumps(payload, sort_keys=True))
    return EXIT.get(payload.get("status", ""), 1)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--runtime", required=True)
    ap.add_argument("--expectations", required=True)
    ap.add_argument("--now-unix", required=True)
    ap.add_argument("--timeout", type=int, default=900)
    # Default stays the clipboard; a path only changes where the artifact is
    # read from, never where the authorization comes from.
    ap.add_argument("--artifact-file", default=None,
                    help="Verify this file instead of the clipboard.")
    args = ap.parse_args(argv)
    if args.timeout < 1 or args.timeout > 3600:
        return emit({
            "status": "refused",
            "reason": "widget-timeout-invalid",
            "detail": "timeout must be between 1 and 3600 seconds",
            "raised_by": "widget",
        })

    expectations_path = Path(args.expectations)
    base = {"expectations_source": str(expectations_path)}

    try:
        # Order matters: the authorization is read BEFORE the artifact, so a
        # missing authorization is reported without ever looking at what is
        # being verified.
        expectations = load_expectations(expectations_path)
        text = (read_artifact_file(Path(args.artifact_file)) if args.artifact_file
                else read_clipboard())
        base["artifact_source"] = args.artifact_file or "clipboard"
        kind, artifact, needs = classify_artifact(text)
        base["artifact_kind"] = kind
        base["artifact_sha256"] = sha256_hex(text.encode("utf-8"))

        if kind == "receipt":
            authorized = lane_expectations(
                expectations, "receipt", RECEIPT_REQUIRED, RECEIPT_OPTIONAL, needs)
            tool, artifact_key = "jackal_verify_receipt", "receipt"
        else:
            authorized = lane_expectations(
                expectations, "bundle", BUNDLE_REQUIRED, BUNDLE_OPTIONAL, needs)
            tool, artifact_key = "jackal_verify_bundle", "bundle"

        base["tool"] = tool
        base["authorized"] = authorized

        tool_args = build_args(kind, artifact_key, artifact, authorized, args.now_unix)
        result = run_front_door(Path(args.runtime), tool, tool_args, args.timeout)
    except Refusal as refusal:
        base.update({"status": "refused", "reason": refusal.reason,
                     "detail": refusal.detail, "raised_by": "widget"})
        return emit(base)

    # Verbatim passthrough. The front door's status is the answer; this router
    # never rewrites it, never softens a refusal, and never retries weaker.
    base.update({
        "status": result.get("status", ""),
        "reason": result.get("reason", ""),
        "detail": result.get("detail", ""),
        "raised_by": "jackal",
        "report": result.get("report", []),
        "front_door": {k: v for k, v in result.items()
                       if k in ("verdict", "receipt_digest_sha256",
                                "certificate_sha256", "checker_sha256",
                                "evaluator_sha256", "enclosure",
                                "expression_operators")},
    })
    return emit(base)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
