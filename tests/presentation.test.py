#!/usr/bin/env python3
"""Regression checks for THOTH, graph, and JOP-UI-001 presentation policy."""

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
cockpit = (ROOT / "Cockpit.qml").read_text(encoding="utf-8")
operator_cli = OPERATOR_CLI.read_text(encoding="utf-8")
png = ASSET.read_bytes()
preview = PREVIEW.read_bytes()

require(manifest["name"] == "JACKAL + THOTH", "manifest identity drifted")
require(
    manifest["barWidget"]["displayName"] == "JACKAL + THOTH",
    "bar display identity drifted",
)
# The bar slot is a PILL: it makes exactly one claim (session function, as a
# single glyph) and carries no answer, ceiling, or result text. Everything that
# states a claim moved to the cockpit, and the assertions moved with it.
require(
    "BarWidget {" in panel and "Model.stateGlyph(root.evidenceState)" in panel,
    "bar surface is no longer a single-glyph status pill",
)
require(
    all(token not in panel for token in (
        "LATEST ANSWER", "GRAPH DECK", "EVIDENCE REGISTER", "resultRow(")),
    "the pill started stating a claim a bar slot cannot qualify",
)
require(
    'value: "74 tools"' in cockpit and 'label: "STEM WORKFLOWS"' in cockpit
    and 'label: "NUMBER THEORY"' in cockpit and 'label: "ENGINEERING"' in cockpit,
    "panel surface totals are stale or incomplete",
)
require(
    "PanelWindow {" in cockpit and "ExclusionMode.Ignore" in cockpit
    and "WlrLayer.Overlay" in cockpit,
    "cockpit no longer claims the full screen plane",
)
require(
    'key: "overview"' in cockpit and "component OverviewSection" in cockpit
    and "StackLayout {" in cockpit,
    "cockpit lost its bird's-eye overview or its section deck",
)
require(
    "GRAPH DECK — LIVE SWEEP" in cockpit
    and "id: graphCanvas" in cockpit
    and "jackal.plotGraph(" in cockpit
    and "A refused sample lifts the pen" in cockpit,
    "live graph deck lost its sweep machinery or its refusal-break rule",
)
require(
    '"/jackal-native", "worksheet"' in service
    and "function plotGraph" in service
    and "function applyGraphJob" in service,
    "graph sweeps no longer run through the runtime's own evaluator",
)
require(
    "bar.barForeground" in panel and "bar.urgent" in panel
    and all(token not in panel for token in ("#050506", "#111214", "#d51f2d")),
    "the pill stopped taking its colours from the operator's bar theme",
)
require(
    all(token in cockpit for token in ("#050506", "#111214", "#c8cdd3", "#f1f3f5", "#d51f2d", "#e8eaed")),
    "professional crimson-and-steel palette drifted",
)
require(
    all(token not in panel for token in ("#00ff78", "#7dffb2", "phosphor", "CRT scanlines", "targeting reticle")),
    "green or moving-text interference decoration returned",
)
require(
    "pixelAligned: true" in cockpit
    and "layer.enabled: true" in cockpit
    and "layer.smooth: false" in cockpit
    and "id: readingPlaneBackground" in cockpit
    and "one opaque device-pixel" in cockpit,
    "stable scrolling text-plane boundary is missing",
)
require(
    "component LatestAnswerCard" in cockpit
    and "LATEST ANSWER  /  LOCAL RECALL" in cockpit
    and "recall only · not re-verified" in cockpit,
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
            "else root.openCockpit()",
        )
    ),
    "pill mouse behavior drifted",
)
require(
    all(
        binding in cockpit
        for binding in (
            "event.modifiers & Qt.ShiftModifier",
            "jackal.refresh()",
            "jackal.verifyArtifact()",
            'jackal.copyText(jackal.packageSha, "package digest")',
            'jackal.copyText(jackal.nonClaim, "non-claim")',
        )
    ),
    "cockpit action keys drifted",
)
require(
    "status=estimated visualization" in cockpit and "pixels are not proof" in cockpit,
    "cockpit dropped the graph assurance boundary",
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

# ---------------------------------------------------------------- JOP-UI-001
# The cockpit is now a JACKAL evidence surface, so the same non-promotion
# policy is enforced on it. These mirror the dropdown checks above; the
# requirement is allocated to both files.

require(
    manifest["kinds"] == ["bar-widget", "overlay"]
    and manifest["entryPoints"]["overlay"] == "Cockpit.qml"
    and manifest.get("keepLoaded") is True,
    "cockpit overlay surface is not declared",
)
require(
    all(token in cockpit for token in
        ("#050506", "#111214", "#c8cdd3", "#f1f3f5", "#d51f2d", "#e8eaed")),
    "cockpit drifted from the machine-HUD palette",
)
require(
    all(token not in cockpit for token in
        ("#00ff78", "#7dffb2", "phosphor", "CRT scanlines", "targeting reticle")),
    "cockpit introduced a decorative colour that can be mistaken for state",
)
require(
    "graph pixels are visualization, never evidence" in cockpit,
    "cockpit no longer labels the graph as non-evidence",
)
require(
    "GRAPH DECK — LIVE SWEEP" in cockpit
    and "jackal.plotGraph(" in cockpit
    and "every sample refused — nothing to plot" in cockpit,
    "cockpit graph deck lost its sweep or its refusal identity",
)
require(
    'Qt.resolvedUrl("assets/jackal-thoth-hellgate-graph.png")' in cockpit,
    "cockpit no longer loads the graph preview",
)
require(
    "THOTH lives inside JACKAL" in cockpit,
    "cockpit no longer states the unified architecture",
)
require(
    'value: "74 tools"' in cockpit and 'label: "STEM WORKFLOWS"' in cockpit,
    "cockpit dropped the declared STEM workflow surface",
)
require(
    "ASSURANCE ≠ CONSEQUENCE" in cockpit
    and "A ceiling is an upper bound, never a grant." in cockpit
    and "Refusal is a first-class answer" in cockpit,
    "cockpit no longer pins the two laws outside the scroll area",
)
require(
    "ASSURANCE" in cockpit and "CONSEQUENCE" in cockpit
    and "never merged into a score" in cockpit,
    "cockpit no longer keeps the two axes apart",
)
require(
    "recall, not evidence" in cockpit,
    "cockpit ledger no longer states that recall is not evidence",
)
require(
    "never from the artifact under review" in cockpit,
    "cockpit verify lane no longer states operator-owned authorization",
)
require(
    "function configuredPluginSettings" in cockpit
    and "shell.shellConfig" in cockpit,
    "cockpit overlay does not merge operator configuration and would "
    "silently fall back to defaults",
)
require(
    'WlrLayershell.namespace: "jackal-cockpit"' in cockpit,
    "cockpit is not namespaced on its own layer-shell surface",
)

print("presentation checks passed")
