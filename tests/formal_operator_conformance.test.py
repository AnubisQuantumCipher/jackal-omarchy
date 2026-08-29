#!/usr/bin/env python3
"""Exhaustive JOP-DOCTOR-001 conformance to the proved SPARK policy."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "bin/omarchy-jackal"
VECTOR_BINARY = ROOT / "formal/bin/jackal_assurance_vectors"

loader = importlib.machinery.SourceFileLoader("jackal_formal_operator", str(CLI))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
operator = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = operator
loader.exec_module(operator)


class FormalOperatorConformanceTests(unittest.TestCase):
    def test_every_spark_doctor_vector_matches_shipped_operator(self) -> None:
        completed = subprocess.run(
            [str(VECTOR_BINARY)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        discovery_map = {
            "DISCOVERY_READY": "ready",
            "DISCOVERY_NOT_INSTALLED": "not-installed",
            "DISCOVERY_REFUSED": "refused",
        }
        seen: set[tuple[str, int]] = set()
        for raw_line in completed.stdout.splitlines():
            fields = [field.strip() for field in raw_line.split("|")]
            if fields[0] != "DOCTOR":
                continue
            discovery = discovery_map[fields[1]]
            mask = int(fields[2])
            expected = fields[3].removeprefix("DOCTOR_")
            actual = operator.doctor_verdict(
                discovery,
                has_probe_rows=bool(mask & 1),
                all_canonical_declared=bool(mask & 2),
                all_probes_pass=bool(mask & 4),
                identity_match=bool(mask & 8),
            )
            self.assertEqual(
                actual,
                expected,
                f"discovery={discovery} mask={mask}",
            )
            seen.add((fields[1], mask))
        self.assertEqual({item[0] for item in seen}, set(discovery_map))
        self.assertEqual({item[1] for item in seen}, set(range(16)))


if __name__ == "__main__":
    unittest.main(verbosity=2)
