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
import threading
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("jackal_artifact_router", ROOT / "verify_artifact.py")
assert spec is not None and spec.loader is not None
router = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = router
spec.loader.exec_module(router)


class RouterTests(unittest.TestCase):
    @unittest.skipUnless(Path('/proc/self/cmdline').exists(), 'Linux procfs required')
    def test_live_process_arguments_exclude_receipt_and_authorization(self):
        for tool, artifact_key in (("jackal_verify_receipt", "receipt"),
                                   ("jackal_verify_bundle", "bundle")):
            with self.subTest(tool=tool), tempfile.TemporaryDirectory() as directory:
                runtime = Path(directory)
                launcher = runtime / 'plugin/hermes/jackal_hermes'
                launcher.parent.mkdir(parents=True)
                ready, release = runtime / 'ready', runtime / 'release'
                launcher.write_text(
                    '#!/usr/bin/python3\nimport json,os,sys,time\nfrom pathlib import Path\n'
                    'request=json.loads(sys.stdin.read())\n'
                    f'Path({str(ready)!r}).write_text(str(os.getpid()))\n'
                    'deadline=time.monotonic()+10\n'
                    f'while not Path({str(release)!r}).exists():\n'
                    ' if time.monotonic()>deadline: sys.exit(2)\n'
                    ' time.sleep(0.01)\n'
                    "print(json.dumps({'jsonrpc':'2.0','id':request['id'],"
                    "'result':{'status':'verified','verdict':'ACCEPT'}}))\n")
                launcher.chmod(0o700)
                results, failures = [], []
                def invoke():
                    try:
                        results.append(router.run_front_door(runtime, tool,
                            {artifact_key: {'private_marker': 'receipt-secret-marker'},
                             'expected_expression': 'operator-secret-marker'}, 15))
                    except BaseException as error:
                        failures.append(error)
                worker = threading.Thread(target=invoke)
                worker.start()
                try:
                    deadline = time.monotonic() + 10
                    while not ready.exists() and worker.is_alive() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertTrue(ready.exists(), repr(failures))
                    command = Path('/proc', ready.read_text(), 'cmdline').read_bytes()
                    self.assertIn(b'stdio', command)
                    self.assertNotIn(b'receipt-secret-marker', command)
                    self.assertNotIn(b'operator-secret-marker', command)
                finally:
                    release.touch()
                    worker.join(20)
                self.assertFalse(worker.is_alive())
                self.assertEqual(failures, [])
                self.assertEqual(results, [{'status': 'verified', 'verdict': 'ACCEPT'}])

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

    def test_private_stdio_preserves_verdict_and_hides_payload_from_argv(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            launcher = runtime / "plugin/hermes/jackal_hermes"
            launcher.parent.mkdir(parents=True)
            launcher.write_text("#!/usr/bin/python3\n"
                "import json,sys\n"
                "assert sys.argv[1:] == ['stdio']\n"
                "request=json.loads(sys.stdin.read())\n"
                "assert request['method'] == 'jackal_verify_receipt'\n"
                "assert request['params'] == {'receipt': 'private-test', 'expected_expression': 'operator-test'}\n"
                "print(json.dumps({'jsonrpc':'2.0','id':request['id'],'result':{'status':'verified','non_claims':['test-only']}}))\n")
            launcher.chmod(0o700)
            result = router.run_front_door(runtime, "jackal_verify_receipt",
                {"receipt": "private-test", "expected_expression": "operator-test"}, 5)
            self.assertEqual(result, {"status": "verified", "non_claims": ["test-only"]})

    def test_rpc_errors_and_wrong_ids_refuse_without_echoing_private_output(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            launcher = runtime / "plugin/hermes/jackal_hermes"
            launcher.parent.mkdir(parents=True)
            for response in [
                {'jsonrpc': '2.0', 'id': 'wrong', 'result': {'status': 'verified'}},
                {'jsonrpc': '2.0', 'id': 'widget-verify', 'error': {'message': 'private-test'}},
                {'jsonrpc': '2.0', 'id': 'widget-verify', 'result': []},
            ]:
                launcher.write_text("#!/usr/bin/python3\nprint(" + repr(json.dumps(response)) + ")\n")
                launcher.chmod(0o700)
                with self.assertRaises(router.Refusal) as caught:
                    router.run_front_door(runtime, "jackal_verify_receipt", {}, 5)
                self.assertEqual(caught.exception.reason, "widget-front-door-unparsable")
                self.assertNotIn('private-test', str(caught.exception))

    def test_duplicate_response_keys_do_not_escape_into_refusal_detail(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            launcher = runtime / "plugin/hermes/jackal_hermes"
            launcher.parent.mkdir(parents=True)
            response = '{"private-test": 1, "private-test": 2}'
            launcher.write_text("#!/usr/bin/python3\nprint(" + repr(response) + ")\n")
            launcher.chmod(0o700)
            with self.assertRaises(router.Refusal) as caught:
                router.run_front_door(runtime, "jackal_verify_receipt", {}, 5)
            self.assertEqual(caught.exception.reason, "widget-front-door-unparsable")
            self.assertEqual(caught.exception.detail, "invalid RPC JSON")

    def test_startup_refusal_preserves_only_recognized_reason(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            launcher = runtime / "plugin/hermes/jackal_hermes"
            launcher.parent.mkdir(parents=True)
            for reason in ("plugin-manifest-missing", "plugin-runtime-unreadable",
                           "plugin-manifest-changed", "plugin-bundle-mismatch", "private-test"):
                response = {"jsonrpc": "2.0", "id": None,
                            "error": {"code": -32000, "message": reason + ": private-test"}}
                launcher.write_text("#!/usr/bin/python3\nimport sys\nprint(" +
                                    repr(json.dumps(response)) + ")\nsys.exit(1)\n")
                launcher.chmod(0o700)
                if reason == "private-test":
                    with self.assertRaises(router.Refusal) as caught:
                        router.run_front_door(runtime, "jackal_verify_receipt", {}, 5)
                    self.assertNotIn("private-test", caught.exception.detail)
                else:
                    self.assertEqual(router.run_front_door(runtime, "jackal_verify_receipt", {}, 5),
                                     {"status": "refused", "reason": reason, "detail": ""})

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
