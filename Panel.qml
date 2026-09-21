// JACKAL + THOTH in the bar — a status pill.
//
// JOP-UI-001: returned assurance vocabulary is rendered without promotion.
//
// This surface makes exactly ONE claim: how well JACKAL's own function is
// established in THIS shell session, as a single glyph. It deliberately shows
// no answer, no ceiling, and no result text, because a bar slot is too small
// to carry the two accounts apart and anything smaller than both of them would
// be a summary — and a summary of an assurance boundary is a promotion of it.
//
// Everything that states a claim lives in the cockpit (Cockpit.qml), which
// carries the full accounts at instrument scale. Clicking here summons it.
//
// The colour rule is the same one the cockpit uses, and it has no middle:
//   established            → the bar's own foreground
//   refusal or downgrade   → the bar's urgent colour
//   not established        → dimmed
// There is deliberately no colour that means "probably fine".

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "khephri.jackal"

  readonly property color barFg: bar ? bar.barForeground : Color.foreground
  readonly property color barUrgentColor: bar ? bar.urgent : Color.urgent

  readonly property string evidenceState: jackal.evidenceState
  readonly property bool affirmative: Model.isAffirmative(root.evidenceState)
  readonly property bool alarming: Model.isAlarming(root.evidenceState)

  readonly property color barIconColor: root.alarming
    ? root.barUrgentColor
    : (root.affirmative ? root.barFg : Qt.darker(root.barFg, 1.55))

  // Guarded: if the shell exposes no summoner this is a no-op rather than a
  // dead control, and the pill still reports session function on its own.
  function openCockpit() {
    if (root.bar && root.bar.shell && root.bar.shell.summon)
      root.bar.shell.summon("khephri.jackal", "{}")
  }

  Service {
    id: jackal
    settings: root.settings
  }

  IpcHandler {
    target: "khephri.jackal"
    function cockpit(): void { root.openCockpit() }
    function open(): void { root.openCockpit() }
    function show(): void { root.openCockpit() }
    function probe(): string { jackal.refresh(); return "probing" }
    function state(): string { return root.evidenceState }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.stateGlyph(root.evidenceState)
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    foreground: root.barIconColor
    tooltipText: Model.tooltip(root.evidenceState, jackal.report,
      jackal.receivedAtMs, jackal.nowMs)

    onPressed: function (buttonCode) {
      if (buttonCode === Qt.RightButton) jackal.refresh()
      else if (buttonCode === Qt.MiddleButton) jackal.runVerify()
      else root.openCockpit()
    }
  }
}
