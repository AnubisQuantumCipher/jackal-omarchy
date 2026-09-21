// JACKAL + THOTH in the bar — the pill, and the dropdown it opens.
//
// JOP-UI-001: returned assurance vocabulary is rendered without promotion.
//
// The pill makes one claim, as a glyph: how well JACKAL's own function is
// established in THIS shell session. Beside it rides a count of ledger rows
// from the last hour — a count of calls, which is recall and says nothing
// about assurance — so the bar shows the kernel being used without stating
// any answer. The dropdown is an ordinary Omarchy panel: hero, activity,
// latest answer, recent feed, actions. The cockpit (Cockpit.qml) carries the
// full accounts at instrument scale.
//
// The colour rule is the cockpit's, and it has no middle:
//   established            → the bar's own foreground
//   refusal or downgrade   → the bar's urgent colour
//   not established        → dimmed
// Accent is used only for chrome and the activity instrument, never for a
// state. There is deliberately no colour that means "probably fine".

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "khephri.jackal"
  ipcTarget: "khephri.jackal"
  // manageIpc: false so this panel owns the single IpcHandler the target
  // permits — needed for the cockpit/probe/state routes below.
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color barFg: bar ? bar.barForeground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property color faint: Util.alpha(foreground, 0.46)

  readonly property string evidenceState: jackal.evidenceState
  readonly property bool affirmative: Model.isAffirmative(root.evidenceState)
  readonly property bool alarming: Model.isAlarming(root.evidenceState)
  readonly property color stateColor: root.alarming
    ? root.urgent : (root.affirmative ? root.foreground : root.dim)
  readonly property color barIconColor: root.alarming
    ? root.urgent : (root.affirmative ? root.barFg : Qt.darker(root.barFg, 1.55))

  // ---- ledger aggregates: counts of rows, nothing more ----------------------
  readonly property int hourMs: 3600 * 1000
  readonly property int windowMs: jackal.activityWindowHours * 3600 * 1000
  readonly property int hourCount:
    Model.rowsWithin(jackal.allResults, jackal.nowMs, root.hourMs).length
  readonly property var summary:
    Model.ledgerSummary(jackal.allResults, jackal.nowMs, root.windowMs)
  readonly property var activity:
    Model.activityBuckets(jackal.allResults, jackal.nowMs, root.windowMs, 24)
  readonly property var newest: jackal.results.length > 0 ? jackal.results[0] : null
  readonly property var recent:
    jackal.results.slice(1, 1 + Math.min(5, Math.max(0, jackal.feedLimit - 1)))
  readonly property bool newestFresh: jackal.ledgerAdvancedAtMs > 0
    && jackal.nowMs - jackal.ledgerAdvancedAtMs < 60000
  readonly property string ageText: Model.ageText(jackal.receivedAtMs, jackal.nowMs)
  readonly property string heroMeta: Model.stateLabel(root.evidenceState)
    + " · " + (jackal.epoch !== "" ? "runtime " + jackal.epoch : "no runtime")
    + " · probed " + root.ageText

  // ---- cursor model ---------------------------------------------------------
  // One highlight across the panel: `focusSection` + index. Vertical order is
  // the latest answer, the recent rows, then the action row; h/l walks the
  // actions. Mouse hover and keys mutate the same state.
  property bool cursorActive: false
  property string focusSection: "actions"   // "feed" | "actions"
  property int selectedIndex: 0
  property int actionIndex: 0

  readonly property var actions: [
    { key: "cockpit", label: "Cockpit", icon: Model.GLYPH.cockpit,
      hint: "Open mission control  (c)" },
    { key: "probe", label: "Probe", icon: Model.GLYPH.refresh,
      hint: "Run the session function probes now  (r)" },
    { key: "verify", label: "Verify clipboard", icon: Model.GLYPH.verified,
      hint: "Route the clipboard artifact to the front door  (v)" }
  ]
  readonly property int feedCount: (root.newest ? 1 : 0) + root.recent.length

  function openCockpit(payload) {
    root.close()
    if (root.bar && root.bar.shell && typeof root.bar.shell.summon === "function")
      root.bar.shell.summon("khephri.jackal", payload || "{}")
  }

  function runAction(key) {
    if (key === "cockpit") root.openCockpit("{}")
    else if (key === "probe") jackal.refresh()
    else if (key === "verify") jackal.verifyArtifact()
  }

  function activateCursor() {
    if (root.focusSection === "actions") {
      var action = root.actions[Math.max(0, Math.min(root.actions.length - 1, root.actionIndex))]
      root.runAction(action.key)
    } else {
      root.openCockpit(JSON.stringify({ section: "ledger" }))
    }
  }

  function moveCursor(dy) {
    if (root.focusSection === "feed") {
      var next = root.selectedIndex + dy
      if (next < 0) next = 0
      if (next >= root.feedCount) { root.focusSection = "actions"; return }
      root.selectedIndex = next
    } else if (dy < 0 && root.feedCount > 0) {
      root.focusSection = "feed"
      root.selectedIndex = root.feedCount - 1
    }
  }

  function moveCursorH(dx) {
    if (root.focusSection !== "actions") return
    root.actionIndex = Math.max(0, Math.min(root.actions.length - 1, root.actionIndex + dx))
  }

  function setFeedCursor(index) {
    root.cursorActive = true
    root.focusSection = "feed"
    root.selectedIndex = index
  }

  function setActionCursor(index) {
    root.cursorActive = true
    root.focusSection = "actions"
    root.actionIndex = index
  }

  onOpenedChanged: {
    jackal.live = opened
    if (opened) {
      jackal.refreshIfStale()
      root.cursorActive = false
      root.focusSection = "actions"
      root.actionIndex = 0
      root.selectedIndex = 0
      if (flick) flick.contentY = 0
    }
  }

  Service {
    id: jackal
    settings: root.settings
  }

  IpcHandler {
    target: "khephri.jackal"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function cockpit(): void { root.openCockpit("{}") }
    // `omarchy-shell khephri.jackal deck ledger` lands the cockpit on a deck.
    function deck(name: string): void { root.openCockpit(JSON.stringify({ section: String(name || "overview") })) }
    function probe(): string { jackal.refresh(); return "probing" }
    function verify(): string { jackal.verifyArtifact(); return "verifying" }
    function state(): string { return root.evidenceState }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ---------------------------------------------------------------- the pill
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.stateGlyph(root.evidenceState)
      + (jackal.barShowActivity && root.hourCount > 0 ? " " + root.hourCount : "")
    slotSize: Style.bar.statusSlot
    // The stock slot is one glyph wide; grow with the painted count so the
    // neighbouring widget cannot paint over the number.
    fixedWidth: vertical ? -1 : Math.max(slotSize, glyphPaintedWidth + Style.spaceReal(8))
    fontSize: Style.font.caption
    foreground: root.barIconColor
    active: false
    tooltipText: Model.tooltip(root.evidenceState, jackal.report,
      jackal.receivedAtMs, jackal.nowMs)
      + (root.hourCount > 0 ? "\n" + Model.countText(root.hourCount, "call", "calls") + " in the last hour (recall)" : "")

    onPressed: function (buttonCode) {
      if (buttonCode === Qt.RightButton) jackal.refresh()
      else if (buttonCode === Qt.MiddleButton) root.openCockpit("{}")
      else root.toggle()
    }

    // A new ledger row lights the accent underline for under a second: the
    // kernel answered something. It carries no class and no verdict.
    Rectangle {
      id: pulse
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(3)
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.max(Style.space(10), parent.width - Style.space(10))
      height: Style.space(2)
      radius: 1
      color: root.accent
      opacity: 0
    }
  }

  SequentialAnimation {
    id: pulseAnimation
    NumberAnimation { target: pulse; property: "opacity"; to: 1; duration: 80 }
    NumberAnimation { target: pulse; property: "opacity"; to: 0; duration: 1100; easing.type: Easing.OutCubic }
  }

  Connections {
    target: jackal
    function onLedgerAdvanced() { pulseAnimation.restart() }
  }

  // ------------------------------------------------------------ the dropdown
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    // Taller than a control panel on purpose: this one reads like a dashboard.
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(720))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; if (dy >= 0 && dx === 0) return }
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) root.moveCursorH(dx)
      }
      onActivateRequested: {
        if (root.cursorActive) root.activateCursor()
        else root.openCockpit("{}")
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") jackal.refresh()
        else if (t === "v" || t === "V") jackal.verifyArtifact()
        else if (t === "c" || t === "C" || t === "o" || t === "O") root.openCockpit("{}")
        else if (t === "g" || t === "G") root.openCockpit(JSON.stringify({ section: "graph" }))
      }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(12)

          // ---------- Hero: state glyph · JACKAL · state/runtime/age ----------
          PanelHero {
            width: parent.width
            title: "JACKAL"
            meta: root.heroMeta
            detail: jackal.probeTotal > 0 ? jackal.probePassed + "/" + jackal.probeTotal : ""
            foreground: root.foreground
            fontFamily: root.fontFamily

            iconComponent: Component {
              Text {
                textFormat: Text.PlainText
                text: Model.stateGlyph(root.evidenceState)
                color: root.stateColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }

            trailingControl: Component {
              Button {
                iconText: Model.GLYPH.cockpit
                tooltipText: "Open the cockpit"
                foreground: root.foreground
                fontFamily: root.fontFamily
                iconSize: Style.font.title
                horizontalPadding: Style.space(6)
                verticalPadding: Style.space(3)
                bordered: true
                onClicked: root.openCockpit("{}")
              }
            }
          }

          // The one sentence for the state, in JACKAL's vocabulary. Only shown
          // when the glyph alone would leave a question open.
          Text {
            visible: !root.affirmative
            width: parent.width
            textFormat: Text.PlainText
            text: Model.stateBlurb(root.evidenceState, jackal.report)
            color: root.alarming ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          // ---------- Activity ----------
          PanelSeparator { foreground: root.foreground }

          Column {
            width: parent.width
            spacing: Style.space(8)

            Item {
              width: parent.width
              implicitHeight: activityHeader.implicitHeight

              PanelSectionHeader {
                id: activityHeader
                text: "ACTIVITY · LAST " + Model.windowLabel(root.windowMs).toUpperCase()
                foreground: root.foreground
                fontFamily: root.fontFamily
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                textFormat: Text.PlainText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "recall, not evidence"
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            JkTimeline {
              width: parent.width
              height: Style.space(72)
              series: root.activity
              foreground: root.foreground
              accent: root.accent
              urgent: root.urgent
              fontFamily: root.fontFamily
            }

            Row {
              width: parent.width
              spacing: Style.space(14)

              Repeater {
                model: [
                  { label: "calls", value: String(root.summary.total) },
                  { label: "refused", value: String(root.summary.refused), alarm: root.summary.refused > 0 },
                  { label: "median", value: Model.formatMs(root.summary.medianMs) },
                  { label: "tools", value: String(root.summary.tools) }
                ]
                delegate: Column {
                  required property var modelData
                  spacing: 0
                  Text {
                    textFormat: Text.PlainText
                    text: modelData.value
                    color: modelData.alarm ? root.urgent : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title
                    font.bold: true
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: modelData.label.toUpperCase()
                    color: root.faint
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.letterSpacing: 1.0
                  }
                }
              }
            }
          }

          // ---------- Latest answer ----------
          PanelSeparator { foreground: root.foreground }

          Column {
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader {
              text: "LATEST ANSWER"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              visible: !root.newest
              width: parent.width
              textFormat: Text.PlainText
              text: "No recorded answer yet. Rows appear here as the kernel is called."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            JkResultRow {
              visible: !!root.newest
              width: parent.width
              row: root.newest
              nowMs: jackal.nowMs
              foreground: root.foreground
              accentColor: root.accent
              urgent: root.urgent
              fontFamily: root.fontFamily
              fresh: root.newestFresh
              hasCursor: root.cursorActive && root.focusSection === "feed" && root.selectedIndex === 0
              onHovered: function(on) { if (on) root.setFeedCursor(0) }
              onClicked: root.openCockpit(JSON.stringify({ section: "ledger" }))
            }
          }

          // ---------- Recent ----------
          Column {
            visible: root.recent.length > 0
            width: parent.width
            spacing: Style.space(2)

            PanelSectionHeader {
              text: "RECENT"
              foreground: root.foreground
              fontFamily: root.fontFamily
              bottomPadding: Style.space(4)
            }

            Repeater {
              model: root.recent
              delegate: JkResultRow {
                required property var modelData
                required property int index
                width: parent.width
                row: modelData
                nowMs: jackal.nowMs
                compact: true
                foreground: root.foreground
                accentColor: root.accent
                urgent: root.urgent
                fontFamily: root.fontFamily
                hasCursor: root.cursorActive && root.focusSection === "feed"
                  && root.selectedIndex === index + 1
                onHovered: function(on) { if (on) root.setFeedCursor(index + 1) }
                onClicked: root.openCockpit(JSON.stringify({ section: "ledger" }))
              }
            }
          }

          // ---------- Actions ----------
          PanelSeparator { foreground: root.foreground }

          Row {
            id: actionRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * (root.actions.length - 1)) / root.actions.length

            Repeater {
              model: root.actions
              delegate: Button {
                required property var modelData
                required property int index
                width: actionRow.cellWidth
                text: modelData.label
                iconText: modelData.icon
                tooltipText: modelData.hint
                iconSpinning: modelData.key === "probe" && jackal.busy
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                iconSize: Style.font.body
                verticalPadding: Style.spacing.controlPaddingY + Style.space(1)
                hasCursor: root.cursorActive && root.focusSection === "actions"
                  && root.actionIndex === index
                onHovered: function(on) { if (on) root.setActionCursor(index) }
                onClicked: root.runAction(modelData.key)
              }
            }
          }

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: jackal.actionStatus !== ""
              ? jackal.actionStatus
              : (jackal.verifyResult
                 ? "Clipboard artifact: " + Model.verifyStatusLabel(jackal.verifyResult.status).toLowerCase()
                   + " · " + Model.verifyRaisedByText(jackal.verifyResult)
                 : "j/k rows · Enter cockpit · r probe · v verify · Esc")
            color: jackal.verifyResult && Model.verifyIsAlarming(jackal.verifyResult) && jackal.actionStatus === ""
              ? root.urgent : root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
