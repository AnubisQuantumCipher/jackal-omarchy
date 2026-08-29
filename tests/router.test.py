#!/usr/bin/env python3
"""Trust-boundary tests for the clipboard and retained-artifact router."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("jackal_artifact_router", ROOT / "verify_artifact.py")
assert spec is not None and spec.loader is not None
router = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = router
spec.loader.exec_module(router)


class RouterTests(unittest.TestCase):
    def test_duplicate_json_keys_refuse(self) -> None:
        with self.assertRaises(router.Refusal) as caught:
            router.strict_json('{"schema":"a","schema":"b"}', "clipboard", "widget-clipboard-not-json")
        self.assertEqual(caught.exception.reason, "widget-clipboard-not-json")

    def test_artifact_cannot_supply_expected_values(self) -> None:
        artifact = {
            "schema": router.RECEIPT_SCHEMA,
            "expected_release_epoch": "artifact-controlled",
        }
        authorized = {
            "expected_release_epoch": "operator-controlled",
            "expected_command": "range-bound-cert",
            "expected_expression": "sqrt(x)",
            "expected_input_lo": "2",
            "expected_input_hi": "3",
        }
        args = router.build_args("receipt", "receipt", artifact, authorized, "10")
        self.assertEqual(args["expected_release_epoch"], "operator-controlled")
        self.assertEqual(args["receipt"]["expected_release_epoch"], "artifact-controlled")

    def test_tolerance_is_routing_not_discovery(self) -> None:
        text = json.dumps(
            {
                "schema": router.RECEIPT_SCHEMA,
                "certificate": {"schema": "jackal-int-cert v1"},
            }
        )
        kind, _artifact, needs = router.classify_artifact(text)
        self.assertEqual(kind, "receipt")
        self.assertEqual(needs, ["expected_tolerance"])

    def test_expectations_symlink_refuses(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "expectations.json"
            target.write_text(json.dumps({"schema": router.EXPECTATIONS_SCHEMA}))
            link = root / "link.json"
            link.symlink_to(target)
            with self.assertRaises(router.Refusal) as caught:
                router.load_expectations(link)
            self.assertEqual(caught.exception.reason, "widget-expectations-unreadable")

    def test_artifact_symlink_refuses(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "artifact.json"
            target.write_text("{}")
            link = root / "link.json"
            link.symlink_to(target)
            with self.assertRaises(router.Refusal) as caught:
                router.read_artifact_file(link)
            self.assertEqual(caught.exception.reason, "widget-artifact-unreadable")

    def test_front_door_launcher_must_be_regular_executable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            real = runtime / "real"
            real.write_text("#!/bin/sh\nexit 0\n")
            real.chmod(real.stat().st_mode | stat.S_IXUSR)
            launcher = runtime / "plugin/hermes/jackal_hermes"
            launcher.parent.mkdir(parents=True)
            launcher.symlink_to(real)
            with self.assertRaises(router.Refusal) as caught:
                router.run_front_door(runtime, "jackal_verify_receipt", {}, 1)
            self.assertEqual(caught.exception.reason, "widget-runtime-absent")

    def test_invalid_timeout_is_named_widget_refusal(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = router.main(
                [
                    "--runtime", "/unused",
                    "--expectations", "/unused",
                    "--now-unix", "1",
                    "--timeout", "0",
                ]
            )
        payload = json.loads(output.getvalue())
        self.assertEqual(code, 1)
        self.assertEqual(payload["reason"], "widget-timeout-invalid")
        self.assertEqual(payload["raised_by"], "widget")

    def test_lane_rejects_unknown_authorization_keys(self) -> None:
        document = {
            "receipt": {
                "expected_release_epoch": "v1.7.2",
                "expected_command": "range-bound-cert",
                "expected_expression": "sqrt(x)",
                "expected_input_lo": "2",
                "expected_input_hi": "3",
                "unexpected": "not admitted",
            }
        }
        with self.assertRaises(router.Refusal) as caught:
            router.lane_expectations(
                document,
                "receipt",
                router.RECEIPT_REQUIRED,
                router.RECEIPT_OPTIONAL,
                [],
            )
        self.assertEqual(caught.exception.reason, "widget-expectations-incomplete")


if __name__ == "__main__":
    unittest.main(verbosity=2)
