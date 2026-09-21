#!/usr/bin/env python3
"""Regression checks for the JACKAL presentation policy (JOP-UI-001).

The bar pill, the dropdown and the full-screen cockpit are JACKAL evidence
surfaces. These checks pin the rules that keep them honest — assurance
vocabulary carried verbatim, refusal identity kept, recall labelled as recall,
the graph labelled as non-evidence, operator-owned authorization for the front
door — and the structural facts that keep them Omarchy-native: every colour
comes from the shell's theme singletons, never from a private palette.
"""

from __future__ import annotations

import hashlib
import json
import re
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets" / "jackal-thoth-hellgate-graph.png"
PREVIEW = ROOT / "preview.png"
OPERATOR_CLI = ROOT / "bin" / "omarchy-jackal"

HEX_COLOR = re.compile(r'"#[0-9A-Fa-f]{3,8}"')


def require(condition: bool, detail: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {detail}")


manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
panel = (ROOT / "Panel.qml").read_text(encoding="utf-8")
service = (ROOT / "Service.qml").read_text(encoding="utf-8")
cockpit = (ROOT / "Cockpit.qml").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
operator_cli = OPERATOR_CLI.read_text(encoding="utf-8")
components = {p.name: p.read_text(encoding="utf-8") for p in sorted(ROOT.glob("Jk*.qml"))}
surfaces = {"Panel.qml": panel, "Cockpit.qml": cockpit, **components}
png = ASSET.read_bytes()
preview = PREVIEW.read_bytes()

# ---------------------------------------------------------------- identity
require(manifest["name"] == "JACKAL + THOTH", "manifest identity drifted")
require(
    manifest["barWidget"]["displayName"] == "JACKAL + THOTH",
    "bar display identity drifted",
)
require(
    manifest["kinds"] == ["bar-widget", "overlay"]
    and manifest["entryPoints"]["barWidget"] == "Panel.qml"
    and manifest["entryPoints"]["overlay"] == "Cockpit.qml"
    and manifest.get("keepLoaded") is True,
    "bar widget + cockpit overlay surfaces are not both declared",
)
require(
    manifest["version"] == (ROOT / "VERSION").read_text(encoding="utf-8").strip(),
    "manifest version and VERSION file disagree",
)
schema_keys = {entry["key"] for entry in manifest["barWidget"]["schema"]}
require(
    {"activityWindowHours", "feedLimit", "barShowActivity", "expectationsPath"} <= schema_keys
    and set(manifest["barWidget"]["defaults"]) >= {"activityWindowHours", "feedLimit", "barShowActivity"},
    "operator settings for the activity instrument are not declared",
)

# ------------------------------------------------------ JOP-UI-001: the pill
# The bar slot states session function as a glyph and, beside it, a count of
# ledger rows from the last hour. A count of calls is recall and says nothing
# about assurance; the pill must never carry an answer, a class or a ceiling.
require(
    "Panel {" in panel and "Model.stateGlyph(root.evidenceState)" in panel
    and "BarIconButton {" in panel,
    "bar surface is no longer a state-glyph pill",
)
require(
    "root.hourCount" in panel and "Model.rowsWithin(jackal.allResults, jackal.nowMs, root.hourMs)" in panel
    and "jackal.barShowActivity" in panel,
    "the pill's hour count is not a bounded count of ledger rows",
)
require(
    all(token not in panel for token in ("EVIDENCE REGISTER", "GRAPH DECK", "assuranceCeiling(")),
    "the pill started stating a claim a bar slot cannot qualify",
)
require(
    "bar.barForeground" in panel and "bar.urgent" in panel and "bar.foreground" in panel,
    "the pill stopped taking its colours from the operator's bar theme",
)
require(
    "if (buttonCode === Qt.RightButton) jackal.refresh()" in panel
    and 'else if (buttonCode === Qt.MiddleButton) root.openCockpit("{}")' in panel
    and "else root.toggle()" in panel,
    "pill mouse behaviour drifted (left dropdown · middle cockpit · right probe)",
)

# ------------------------------------------------- the dropdown, kit-native
require(
    "KeyboardPanel {" in panel and "PanelKeyCatcher {" in panel and "PanelHero {" in panel
    and "PanelSectionHeader {" in panel and "PanelSeparator {" in panel,
    "the dropdown no longer uses the Omarchy panel kit",
)
require(
    "recall, not evidence" in panel and "LATEST ANSWER" in panel and "ACTIVITY" in panel,
    "the dropdown lost its recall boundary or its activity instrument",
)
require(
    "onTabRequested: function(direction) { root.switchPanel(direction) }" in panel,
    "the dropdown no longer hands Tab to the bar's panel switcher",
)
require(
    'summon("khephri.jackal"' in panel and "function deck(name: string)" in panel,
    "the dropdown cannot summon the cockpit onto a deck",
)

# ------------------------------------------------- JOP-UI-001: the cockpit
require(
    "PanelWindow {" in cockpit and "ExclusionMode.Ignore" in cockpit
    and "WlrLayer.Overlay" in cockpit
    and 'WlrLayershell.namespace: "jackal-cockpit"' in cockpit,
    "cockpit no longer claims its own full-screen layer-shell plane",
)
require(
    "StackLayout {" in cockpit and "component OverviewSection" in cockpit
    and all(f'key: "{k}"' in cockpit for k in
            ("overview", "ledger", "graph", "probes", "verify", "register", "thoth")),
    "cockpit lost a deck",
)
require(
    "Color.menu.background" in cockpit and "Color.menu.text" in cockpit
    and "Color.menu.scrim" in cockpit and "Color.accent" in cockpit and "Color.urgent" in cockpit
    and "Style.font.menuFamily" in cockpit and "Style.cornerRadius" in cockpit,
    "cockpit stopped drawing from the operator's theme singletons",
)
for name, text in surfaces.items():
    require(
        not HEX_COLOR.search(text),
        f"{name} carries a private hex colour; every colour must come from the theme",
    )
    require(
        all(token not in text for token in ("phosphor", "CRT scanlines", "targeting reticle")),
        f"{name} reintroduced moving-text interference decoration",
    )
require(
    "readonly property color stateColor: root.alarming" in cockpit
    and "? root.urgent : (root.affirmative ? root.foreground : root.dim)" in cockpit,
    "cockpit state colour grew a middle value",
)
require(
    "ASSURANCE ≠ CONSEQUENCE" in cockpit
    and "A ceiling is an upper bound, never a grant." in cockpit
    and "Refusal is a first-class answer" in cockpit,
    "cockpit no longer pins the two laws outside the scroll area",
)
require(
    "never merged into a score" in cockpit and "both axes" in cockpit,
    "cockpit no longer keeps the two axes apart",
)
require(
    "recall, not evidence" in cockpit and "Ledger — local recall" in cockpit,
    "cockpit ledger no longer states that recall is not evidence",
)
require(
    "never from the artifact under review" in cockpit
    and "Retained receipts" in cockpit and "jackal.verifyReceiptDigest(" in cockpit,
    "cockpit verify lane lost operator-owned authorization or receipt re-verification",
)
require(
    "graph pixels are visualization, never evidence" in cockpit
    and "status=estimated visualization" in cockpit
    and "pixels are not proof" in cockpit
    and "id: graphCanvas" in cockpit and "jackal.plotGraph(" in cockpit
    and "A refused sample lifts the pen" in cockpit
    and "every sample refused — nothing to plot" in cockpit,
    "live graph deck lost its sweep machinery, its refusal-break rule or its non-evidence label",
)
require(
    'Qt.resolvedUrl("assets/jackal-thoth-hellgate-graph.png")' in cockpit
    and "THOTH lives inside JACKAL" in cockpit,
    "cockpit no longer states the unified architecture or shows the reference render",
)
require(
    "function configuredPluginSettings" in cockpit and "shell.shellConfig" in cockpit,
    "cockpit overlay does not merge operator configuration and would silently fall back to defaults",
)
require(
    "passive: true" in cockpit,
    "cockpit service probes on its own clock; two surfaces would run two doctors",
)
require(
    all(binding in cockpit for binding in (
        "event.modifiers & Qt.ShiftModifier",
        "jackal.refresh()",
        "jackal.verifyArtifact()",
        'jackal.copyText(jackal.packageSha, "package digest")',
        'jackal.copyText(jackal.nonClaim, "non-claim")',
    )),
    "cockpit action keys drifted",
)
# No typed-in surface totals: every number on the THOTH deck is read from the
# runtime or the ledger. The old hardcoded "74 tools" tiles are exactly the
# promotion this policy forbids.
require(
    '"74 tools"' not in cockpit and "STEM WORKFLOWS" not in cockpit,
    "cockpit reintroduced a typed-in surface total",
)

# ---------------------------------------------------------- shared components
require(
    {"JkResultRow.qml", "JkTimeline.qml", "JkSpectrum.qml", "JkChip.qml", "JkStat.qml"} <= set(components),
    "a shared instrument component is missing",
)
row = components["JkResultRow.qml"]
require(
    "tone: root.refused ? root.urgent : root.foreground" in row
    and "root.refused ? root.urgent : root.dim" in row,
    "the result row tints answer classes; only refusal may take the refusal colour",
)
require(
    "RECEIPT RETAINED" in row and "RECEIPT GONE" in row,
    "the result row no longer separates a retained receipt from a digest without one",
)
timeline = components["JkTimeline.qml"]
require(
    "b.answered" in timeline and "b.refused" in timeline and "root.urgent" in timeline,
    "the activity instrument no longer stacks refusals apart from answers",
)
spectrum = components["JkSpectrum.qml"]
require(
    "modelData.refused" in spectrum and "? root.urgent" in spectrum,
    "the status spectrum lost the refusal colour",
)

# ----------------------------------------------------------------- service
require(
    "FileView" in service and "watchChanges: true" in service
    and "onFileChanged: resultsRefresh.restart()" in service,
    "latest-result live refresh watcher is missing",
)
require(
    '"/jackal-native", "worksheet"' in service and "function plotGraph" in service
    and "function applyGraphJob" in service,
    "graph sweeps no longer run through the runtime's own evaluator",
)
require(
    "Model.parseLedger(outText)" in service and "signal ledgerAdvanced()" in service
    and "property bool passive" in service,
    "service lost the full-ledger read, the advance signal or passive mode",
)
require(
    'root.pluginDir + "/bin/omarchy-jackal"' in service,
    "panel no longer uses the repository-bundled operator CLI",
)
require(
    all(executable in service for executable in ('"/usr/bin/python3"', '"/usr/bin/cat"', '"/usr/bin/wl-copy"', '"/usr/bin/ls"'))
    and all(bare not in service for bare in ('["python3",', '["cat",', '["wl-copy",', '["ls",')),
    "QML subprocess execution returned to PATH-dependent commands",
)
require(
    "/^[0-9a-f]{64}\\.json$/" in service and 'if (!/^[0-9a-f]{64}$/.test(d)) return' in service,
    "receipt paths are no longer derived from digests alone",
)
require(
    "sys.dont_write_bytecode = True" in operator_cli
    and "core-plugin-identity-refused" in operator_cli,
    "runtime verification can contaminate the identity-pinned plugin tree",
)

# ------------------------------------------------------------------ README
require(
    "THOTH is the name of JACKAL's integrated" in readme,
    "README no longer states the unified architecture",
)
require(
    "A green bar means" not in readme,
    "README returned the retired green status language",
)
require(
    "`status=bounded`, `formal=false`" in readme,
    "README dropped the HELLGATE assurance boundary",
)

# ------------------------------------------------------------------ assets
require(png.startswith(b"\x89PNG\r\n\x1a\n"), "graph preview is not a PNG")
require(png[12:16] == b"IHDR", "graph preview has no leading IHDR chunk")
require(struct.unpack(">II", png[16:24]) == (1200, 720), "graph preview dimensions drifted")
require(
    hashlib.sha256(png).hexdigest()
    == "cd5f5c2af87a0a2583b49c1b54bffc8af42a20b6cd7df09186e05296ca79be0e",
    "graph preview is no longer the approved reference render",
)
require(preview.startswith(b"\x89PNG\r\n\x1a\n"), "marketplace preview is not PNG")
require(preview[12:16] == b"IHDR", "marketplace preview has no leading IHDR")
preview_width, preview_height = struct.unpack(">II", preview[16:24])
require(preview_height > preview_width, "marketplace preview is not the captured portrait dropdown")

print("presentation checks passed")
