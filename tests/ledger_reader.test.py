#!/usr/bin/python3
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("reader", ROOT / "read_ledger.py")
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)

class ReaderTests(unittest.TestCase):
    def test_complete_valid_ledger_and_exact_limit(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "ledger"
            data = b'{"status":"exact"}\n'
            p.write_bytes(data)
            with mock.patch.object(reader, "MAX_LEDGER_BYTES", len(data)):
                self.assertEqual(reader.read_ledger(p), data)

    def test_refuses_oversize_invalid_utf8_symlink_and_fifo(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "ledger"
            p.write_bytes(b"oversized")
            with mock.patch.object(reader, "MAX_LEDGER_BYTES", 1):
                with self.assertRaises(ValueError): reader.read_ledger(p)
            p.write_bytes(b"\xff")
            with self.assertRaises(ValueError): reader.read_ledger(p)
            link = Path(d) / "link"
            link.symlink_to(p)
            with self.assertRaises(OSError): reader.read_ledger(link)
            fifo = Path(d) / "fifo"
            os.mkfifo(fifo)
            with self.assertRaises(ValueError): reader.read_ledger(fifo)

    def test_cli_refusal_emits_no_partial_ledger(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "ledger"
            with p.open("wb") as f: f.truncate(reader.MAX_LEDGER_BYTES + 1)
            result = subprocess.run([sys.executable, str(ROOT / "read_ledger.py"), str(p)],
                                    capture_output=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, b"")

    def test_fileview_cannot_read_independently(self):
        service = (ROOT / "Service.qml").read_text()
        watcher = service.split("id: resultsFileWatch", 1)[1].split("}", 1)[0]
        self.assertIn("preload: false", watcher)
        self.assertIn("blockAllReads: true", watcher)
        self.assertIn('pluginDir + "/read_ledger.py"', service)

if __name__ == "__main__": unittest.main(verbosity=2)
