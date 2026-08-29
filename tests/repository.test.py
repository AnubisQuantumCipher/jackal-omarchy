#!/usr/bin/env python3
"""Marketplace, release, and repository policy checks (JOP-CI-001)."""

from __future__ import annotations

import json
import re
import stat
import struct
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")


required = [
    "manifest.json",
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "Panel.qml",
    "Service.qml",
    "Model.js",
    "verify_artifact.py",
    "assurance/requirements.json",
    "formal/jackal_assurance.gpr",
    "tests/formal_operator_conformance.test.py",
    ".github/workflows/assurance.yml",
    "preview.png",
    "bin/omarchy-jackal",
    "bin/jackal-mcp-ledger",
]
for name in required:
    require((ROOT / name).is_file(), f"required root file missing: {name}")

manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
require(manifest["schemaVersion"] == 1, "unsupported manifest schema")
require(manifest["id"] == "khephri.jackal", "permanent plugin id drifted")
require(manifest["version"] == version, "manifest and VERSION disagree")
require(manifest["license"] == "MIT", "manifest is not MIT licensed")
require(manifest["entryPoints"]["barWidget"] == "Panel.qml", "entry point drifted")

readme = (ROOT / "README.md").read_text(encoding="utf-8")
for phrase in (
    "omarchy plugin add",
    "omarchy plugin remove",
    "Runtime dependencies",
    "unsandboxed",
    "MIT License",
):
    require(phrase in readme, f"README is missing marketplace disclosure: {phrase}")

# Relative documentation links are part of the release interface.  Validate
# them locally without following network links or pretending that a reachable
# external site is trustworthy.
markdown_link = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
for document in sorted(ROOT.rglob("*.md")):
    if ".git" in document.parts:
        continue
    source = document.read_text(encoding="utf-8")
    for match in markdown_link.finditer(source):
        raw_target = match.group(1).strip()
        if raw_target.startswith(("https://", "http://", "mailto:", "#")):
            continue
        if raw_target.startswith("<") and raw_target.endswith(">"):
            raw_target = raw_target[1:-1]
        target_text = unquote(raw_target.split("#", 1)[0])
        if not target_text:
            continue
        target = (document.parent / target_text).resolve()
        require(
            target.is_relative_to(ROOT),
            f"documentation link escapes repository: {document} -> {raw_target}",
        )
        require(
            target.exists(),
            f"broken local documentation link: {document} -> {raw_target}",
        )

for path in ROOT.rglob("*"):
    if ".git" in path.parts:
        continue
    require(not path.is_symlink(), f"repository contains forbidden symlink: {path}")

text_extensions = {
    ".md", ".json", ".py", ".qml", ".js", ".mjs", ".sh", ".yml", ".yaml", ".cff", ""
}
texts: list[tuple[Path, str]] = []
for path in ROOT.rglob("*"):
    if not path.is_file() or ".git" in path.parts or path.suffix.lower() not in text_extensions:
        continue
    try:
        texts.append((path, path.read_text(encoding="utf-8")))
    except UnicodeDecodeError:
        pass

joined = "\n".join(value for _path, value in texts)
developer_home = "/" + "home" + "/" + "sicarii"
github_pat_prefix = "gh" + "p_"
private_key_marker = "BEGIN " + "OPENSSH PRIVATE KEY"
sudoers_marker = "NOPASS" + "WD"
require(developer_home not in joined, "developer-specific absolute home path is tracked")
require(github_pat_prefix not in joined, "GitHub personal access token pattern is tracked")
require(private_key_marker not in joined, "private key material is tracked")
require(not re.search(r"curl\s+[^\n|]+\|\s*(?:ba)?sh", joined), "download-to-shell pattern found")
require(sudoers_marker not in joined, "sudoers policy text found")

preview = (ROOT / "preview.png").read_bytes()
require(preview.startswith(b"\x89PNG\r\n\x1a\n"), "preview is not PNG")
require(preview[12:16] == b"IHDR", "preview has no leading IHDR")
width, height = struct.unpack(">II", preview[16:24])
require(width > 0 and height > 0, "preview dimensions are invalid")
require(len(preview) < 50 * 1024 * 1024, "preview exceeds marketplace byte limit")
require(width * height < 40_000_000, "preview exceeds marketplace pixel limit")

workflow = (ROOT / ".github/workflows/assurance.yml").read_text(encoding="utf-8")
require("JOP-CI-001" in workflow, "workflow lacks its assurance requirement link")
require("JACKAL_REQUIRE_FORMAL" in workflow, "workflow does not require formal proof")
for toolchain_pin in (
    "gnat_native=16.1.0",
    "gprbuild=26.0.1",
    "gnatprove=16.1.0",
):
    require(toolchain_pin in workflow, f"workflow lacks toolchain pin: {toolchain_pin}")
for use in re.findall(r"uses:\s*([^\s#]+)", workflow):
    require(
        re.fullmatch(r"[^@\s]+@[0-9a-f]{40}", use) is not None,
        f"workflow action is not pinned to an immutable commit: {use}",
    )
alire_action = (
    "alire-project/alr-install@b99b8c21417c79c307905439def2718bc393b94a"
)
temporary_prefix = "prefix: ${{ runner.temp }}/jackal-alire"
require(alire_action in workflow, "workflow lacks the pinned Alire installer")
require(
    workflow.count(alire_action) == workflow.count(temporary_prefix),
    "every Alire install must stay outside the repository checkout",
)

for executable in (
    ROOT / "bin/omarchy-jackal",
    ROOT / "bin/jackal-mcp-ledger",
    ROOT / "scripts/check.sh",
    ROOT / "scripts/check-formal.sh",
    ROOT / "scripts/check-traceability.py",
    ROOT / "scripts/package-release.sh",
    ROOT / "scripts/check-release-reproducibility.sh",
    ROOT / "scripts/release-gate.sh",
):
    require(executable.stat().st_mode & stat.S_IXUSR, f"script is not executable: {executable}")

service = (ROOT / "Service.qml").read_text(encoding="utf-8")
require('root.pluginDir + "/bin/omarchy-jackal"' in service, "service does not use bundled operator CLI")

print("repository policy checks passed")
