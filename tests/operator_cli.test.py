#!/usr/bin/env python3
"""Unit and policy checks for the bundled operator CLI."""

from __future__ import annotations

import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "bin/omarchy-jackal"

loader = importlib.machinery.SourceFileLoader("jackal_omarchy_operator", str(CLI))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
operator = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = operator
loader.exec_module(operator)


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value), encoding="utf-8")


def make_runtime(base: Path) -> tuple[Path, Path]:
    runtime = base / "runtimes/v-test"
    launcher = runtime / "plugin/hermes/jackal_hermes"
    launcher.parent.mkdir(parents=True)
    launcher.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
    launcher.chmod(launcher.stat().st_mode | stat.S_IXUSR)
    package = {
        "schema": "jackal-runtime-package-v1",
        "epoch": "v-test",
        "asset": "jackal-test.tar.gz",
        "package_sha256": "a" * 64,
        "package_size": 7,
    }
    write_json(runtime / ".jackal-package.json", package)
    write_json(
        runtime / "capability_inventory_v1.json",
        {
            "schema": "jackal-capability-inventory-v1",
            "tool_count": 1,
            "tools": [
                {
                    "name": "jackal_exact",
                    "status_classes": ["exact", "refused"],
                }
            ],
        },
    )
    locator = base / "runtime.json"
    write_json(
        locator,
        {
            "schema": "jackal-codex-plugin-runtime-v1",
            "epoch": "v-test",
            "package_sha256": "a" * 64,
            "package_size": 7,
            "runtime_path": str(runtime),
        },
    )
    return runtime, locator


class OperatorTests(unittest.TestCase):
    def test_version_is_repository_version(self) -> None:
        result = subprocess.run(
            [str(CLI), "--version"], capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn((ROOT / "VERSION").read_text().strip(), result.stdout)

    def test_source_has_no_developer_home_or_fixed_runtime(self) -> None:
        source = CLI.read_text(encoding="utf-8")
        self.assertNotIn("/" + "home" + "/" + "sicarii", source)
        self.assertNotIn('runtimes/v1.7.3"', source)
        self.assertIn("runtime-locator", source)

    def test_runtime_locator_and_package_must_agree(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            runtime, locator = make_runtime(Path(directory))
            with mock.patch.object(operator, "LOCATOR_PATH", locator), mock.patch.dict(
                os.environ, {"JACKAL_HOME": ""}
            ):
                context = operator.runtime_context()
                self.assertEqual(context.root, runtime)
                value = json.loads(locator.read_text())
                value["package_size"] = 8
                write_json(locator, value)
                with self.assertRaisesRegex(
                    operator.OperatorRefusal, "runtime-locator-package_size-mismatch"
                ):
                    operator.runtime_context()

    def test_runtime_path_must_be_canonical(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            runtime, locator = make_runtime(base)
            alias = base / "runtime-alias"
            alias.symlink_to(runtime, target_is_directory=True)
            value = json.loads(locator.read_text())
            value["runtime_path"] = str(alias)
            write_json(locator, value)
            with mock.patch.object(operator, "LOCATOR_PATH", locator), mock.patch.dict(
                os.environ, {"JACKAL_HOME": ""}
            ):
                with self.assertRaisesRegex(
                    operator.OperatorRefusal, "runtime-path-not-canonical"
                ):
                    operator.runtime_context()

    def test_inventory_duplicate_names_refuse(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            runtime, locator = make_runtime(Path(directory))
            inventory = json.loads(
                (runtime / "capability_inventory_v1.json").read_text()
            )
            inventory["tools"].append(dict(inventory["tools"][0]))
            inventory["tool_count"] = 2
            write_json(runtime / "capability_inventory_v1.json", inventory)
            with mock.patch.object(operator, "LOCATOR_PATH", locator), mock.patch.dict(
                os.environ, {"JACKAL_HOME": ""}
            ):
                context = operator.runtime_context()
                with self.assertRaisesRegex(
                    operator.OperatorRefusal, "capability-inventory-name-duplicate"
                ):
                    operator.capability_inventory(context)

    def test_doctor_requires_observed_function_and_identity(self) -> None:
        context = operator.RuntimeContext(
            root=Path("/tmp/runtime"),
            launcher=Path("/tmp/runtime/launcher"),
            locator=None,
            package={
                "epoch": "v-test",
                "package_sha256": "a" * 64,
                "package_size": 7,
                "asset": "test",
            },
        )
        inventory = {
            "tool_count": 1,
            "tools": [
                {
                    "name": "jackal_exact",
                    "status_classes": ["exact", "refused"],
                }
            ],
        }
        with mock.patch.object(operator, "load_config", return_value={}), mock.patch.object(
            operator, "runtime_context", return_value=context
        ), mock.patch.object(
            operator, "capability_inventory", return_value=inventory
        ), mock.patch.object(
            operator, "call_tool", return_value={"status": "exact"}
        ), mock.patch.object(
            operator, "_selftest", return_value=(True, "")
        ), mock.patch.object(
            operator, "file_sha256", return_value="b" * 64
        ):
            report = operator._doctor_document()
        self.assertEqual(report["doctor_verdict"], "FUNCTIONAL")
        self.assertTrue(report["function"]["exact"]["functional_pass"])

    def test_decision_probe_uses_admissible_identifier_tokens(self) -> None:
        _tool, arguments, expected = operator.CANONICAL_PROBES["decision"]
        assert arguments is not None
        self.assertEqual(expected, "exact")
        self.assertIsNotNone(re.fullmatch(r"[A-Za-z0-9_]+", arguments["decision_id"]))
        self.assertIsNotNone(re.fullmatch(r"[A-Za-z0-9_]+", arguments["criterion"]))

    def test_uninstall_without_explicit_yes_refuses_without_resolution(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output), mock.patch.object(
            operator, "runtime_context"
        ) as context:
            code = operator.command_uninstall(Namespace(yes=False))
        self.assertEqual(code, 1)
        self.assertFalse(context.called)
        self.assertEqual(json.loads(output.getvalue())["uninstall"], "REFUSED")

    def test_relative_provisioner_path_refuses(self) -> None:
        with mock.patch.dict(os.environ, {"JACKAL_PROVISIONER": "relative.py"}):
            with self.assertRaisesRegex(
                operator.OperatorRefusal, "core-provisioner-not-found"
            ):
                operator._provisioner_path({})


if __name__ == "__main__":
    unittest.main(verbosity=2)
