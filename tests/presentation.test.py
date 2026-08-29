#!/usr/bin/env python3
"""Regression checks for the integrated THOTH identity and graph preview."""

from __future__ import annotations

import json
import hashlib
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets" / "jackal-thoth-hellgate-graph.png"
PREVIEW = ROOT / "preview.png"
OPERATOR_CLI = ROOT / "bin" / "omarchy-jackal"


def require(condition: bool, detail: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {detail}")


manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
panel = (ROOT / "Panel.qml").read_text(encoding="utf-8")
service = (ROOT / "Service.qml").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
operator_cli = OPERATOR_CLI.read_text(encoding="utf-8")
png = ASSET.read_bytes()
preview = PREVIEW.read_bytes()

require(manifest["name"] == "JACKAL + THOTH", "manifest identity drifted")
require(
    manifest["barWidget"]["displayName"] == "JACKAL + THOTH",
    "bar display identity drifted",
)
require(
    'Qt.resolvedUrl("assets/jackal-thoth-hellgate-graph.png")' in panel,
    "panel no longer loads the graph preview",
)
require(
    "THOTH lives inside JACKAL" in panel,
    "panel no longer states the unified architecture",
)
require(
    'value: "58 tools"' in panel and 'label: "STEM WORKFLOWS"' in panel,
    "panel surface totals are stale or incomplete",
)
require(
    all(token in panel for token in ("#050506", "#111214", "#c8cdd3", "#f1f3f5", "#d51f2d", "#e8eaed")),
    "professional crimson-and-steel palette drifted",
)
require(
    all(token not in panel for token in ("#00ff78", "#7dffb2", "phosphor", "CRT scanlines", "targeting reticle")),
    "green or moving-text interference decoration returned",
)
require(
    "pixelAligned: true" in panel
    and "layer.enabled: true" in panel
    and "layer.smooth: false" in panel
    and "id: readingPlaneBackground" in panel
    and "one opaque device-pixel" in panel,
    "stable scrolling text-plane boundary is missing",
)
require(
    "component LatestAnswerCard" in panel
    and "LATEST ANSWER  /  LOCAL RECALL" in panel
    and "recall only · not re-verified" in panel,
    "newest-answer command strip lost its recall boundary",
)
require(
    "FileView" in service
    and "watchChanges: true" in service
    and "onFileChanged: resultsRefresh.restart()" in service,
    "latest-result live refresh watcher is missing",
)
require(
    "sys.dont_write_bytecode = True" in operator_cli
    and "core-plugin-identity-refused" in operator_cli,
    "runtime verification can contaminate the identity-pinned plugin tree",
)
require(
    'root.pluginDir + "/bin/omarchy-jackal"' in service,
    "panel no longer uses the repository-bundled operator CLI",
)
require(
    all(
        executable in service
        for executable in (
            '"/usr/bin/python3"',
            '"/usr/bin/cat"',
            '"/usr/bin/wl-copy"',
        )
    )
    and all(
        bare not in service
        for bare in ('["python3",', '["cat",', '["wl-copy",')
    ),
    "QML subprocess execution returned to PATH-dependent commands",
)
require(
    all(
        binding in panel
        for binding in (
            "if (buttonCode === Qt.RightButton) jackal.refresh()",
            "else if (buttonCode === Qt.MiddleButton) jackal.runVerify()",
            "else root.toggle()",
            'if (key === "r") jackal.refresh()',
            'else if (key === "v") jackal.runVerify()',
            'else if (key === "c") jackal.copyText(jackal.packageSha, "package digest")',
            'else if (key === "n") jackal.copyText(jackal.nonClaim, "non-claim")',
            'else if (key === "p") jackal.verifyArtifact()',
        )
    ),
    "dropdown mouse or keyboard behavior drifted",
)
require(
    "status=estimated visualization" in panel and "pixels are not proof" in panel,
    "panel dropped the graph assurance boundary",
)
require(
    "THOTH is the name of JACKAL's integrated" in readme,
    "README no longer states the unified architecture",
)
require(
    "A green bar means" not in readme and "A white instrument bar means" in readme,
    "README returned the retired green status language",
)
require(
    "`status=bounded`, `formal=false`" in readme,
    "README dropped the HELLGATE assurance boundary",
)
require(png.startswith(b"\x89PNG\r\n\x1a\n"), "graph preview is not a PNG")
require(png[12:16] == b"IHDR", "graph preview has no leading IHDR chunk")
require(
    struct.unpack(">II", png[16:24]) == (1200, 720),
    "graph preview dimensions drifted",
)
require(
    hashlib.sha256(png).hexdigest()
    == "cd5f5c2af87a0a2583b49c1b54bffc8af42a20b6cd7df09186e05296ca79be0e",
    "graph preview is no longer the approved crimson-and-steel render",
)
require(preview.startswith(b"\x89PNG\r\n\x1a\n"), "marketplace preview is not PNG")
require(preview[12:16] == b"IHDR", "marketplace preview has no leading IHDR")
preview_width, preview_height = struct.unpack(">II", preview[16:24])
require(
    preview_height > preview_width,
    "marketplace preview is not the captured portrait dropdown",
)

print("presentation checks passed")
