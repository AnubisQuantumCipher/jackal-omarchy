// JACKAL COCKPIT — full-screen mission control for the evidence kernel.
//
// Overlay kind: summoned from the bar widget, dismissed with Esc / ✕.
// JOP-UI-001: returned assurance vocabulary is rendered without promotion.
//
// JACKAL is a mathematical evidence kernel: every answer declares what kind of
// answer it is, refusal is a first-class answer, and two independent things are
// always stated — how well a fact is established (ASSURANCE) and what may be
// decided on it (CONSEQUENCE). A ceiling is an upper bound, never a grant.
//
// THOTH is JACKAL's integrated measurement/provenance subsystem, not a second
// engine. This cockpit is built to preserve that architecture and JACKAL's
// assurance boundaries rather than summarise them away, so it keeps these
// accounts strictly apart and never merges them into a score:
//
//   GRAPH              an explicitly NON-EVIDENTIARY sweep of the sealed
//                      evaluator. Graph pixels are visualization, never
//                      evidence, and the canvas says so on its face.
//   PROBES             function — established only by tools executed in this
//                      shell session. Nothing else may colour the indicator.
//   LEDGER             local recall of returned answers. Recall is not
//                      evidence; the ledger is a file this tooling wrote.
//   VERIFY             the one section that ACTS. Routes a clipboard receipt or
//                      bundle to a real front door and prints its verdict
//                      verbatim, against an authorization the operator owns —
//                      never one taken from the artifact under review.
//   THOTH              integrated measurement/provenance and the sealed runtime
//                      identity. Exact-given remains conditional on its datum.
//   REGISTER           capability — what actually stands behind an answer from
//                      each family, with both axes, from the release's own
//                      generated `capability_inventory_v1.json`.
//
// The two laws and the engine's governing non-claim are pinned outside every
// scroll area, because they are the lines that must never be scrolled away.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root

  // Injected by the Omarchy shell for overlay-kind plugins.
  property var shell: ({})
  property var manifest: ({})
  property bool opened: false

  property string section: "overview"
  property int registerIndex: 0
  property string hoverNav: ""

  readonly property var sections: [
    { key: "overview", label: "OVERVIEW", hint: "everything at once" },
    { key: "graph",    label: "GRAPH",    hint: "non-evidentiary sweep" },
    { key: "probes",   label: "PROBES",   hint: "session function" },
    { key: "ledger",   label: "LEDGER",   hint: "local recall" },
    { key: "verify",   label: "VERIFY",   hint: "front door" },
    { key: "thoth",    label: "THOTH",    hint: "measurement" },
    { key: "register", label: "REGISTER", hint: "capability" }
  ]

  readonly property string pluginId:
    root.manifest && typeof root.manifest.id === "string"
      && root.manifest.id !== "" ? root.manifest.id : "khephri.jackal"

  // Machine-HUD palette shared with the bar dropdown: matte graphite, cold
  // instrument white, one disciplined crimson channel. No green, and no
  // decorative colour that can be mistaken for evidence state.
  readonly property color panelVoid: "#050506"
  readonly property color panelSurface: "#111214"
  readonly property color panelRaised: "#17191c"
  readonly property color telemetry: "#c8cdd3"
  readonly property color signal: "#f1f3f5"
  readonly property color reentry: "#d51f2d"
  readonly property color frost: "#e8eaed"
  readonly property color dim: Qt.alpha(root.frost, 0.68)
  readonly property color faint: Qt.alpha(root.frost, 0.44)
  readonly property color hairline: Qt.alpha(root.frost, 0.12)

  readonly property string fontFamily: Style.font.family

  readonly property string evidenceState: jackal.evidenceState
  readonly property bool affirmative: Model.isAffirmative(root.evidenceState)
  readonly property bool alarming: Model.isAlarming(root.evidenceState)
  readonly property color stateColor: root.alarming
    ? root.reentry : (root.affirmative ? root.signal : root.dim)

  readonly property string ageText:
    Model.ageText(jackal.receivedAtMs, jackal.nowMs)

  // ---------------------------------------------------------------- settings
  // Overlays are NOT handed `settings` by the shell the way bar widgets are.
  // The overlay has to walk the shell config itself; if this is skipped the
  // failure is silent and every value quietly falls back to a default.

  function isPlainRecord(value) {
    return !!value && typeof value === "object" && !Array.isArray(value)
  }

  function copyPluginSettings(entry) {
    var copied = ({})
    if (!root.isPlainRecord(entry)) return copied
    for (var key in entry) {
      if (key === "id") continue
      copied[key] = entry[key]
    }
    if (root.isPlainRecord(entry.settings)) {
      for (var inner in entry.settings) copied[inner] = entry.settings[inner]
    }
    return copied
  }

  function configuredPluginSettings() {
    const config = root.shell ? root.shell.shellConfig : null
    const layout = config && config.bar ? config.bar.layout : null
    const names = ["left", "center", "right"]
    const wanted = Util.canonicalWidgetId(root.pluginId)
    if (layout) {
      for (var s = 0; s < names.length; s++) {
        const entries = layout[names[s]]
        if (!Array.isArray(entries)) continue
        for (var i = 0; i < entries.length; i++) {
          const entry = entries[i]
          const id = Util.canonicalWidgetId(String(
            entry && entry.id !== undefined ? entry.id : entry || ""))
          if (id === wanted) return root.copyPluginSettings(entry)
        }
      }
    }
    const plugins = config ? config.plugins : null
    if (Array.isArray(plugins)) {
      for (var p = 0; p < plugins.length; p++) {
        const entry2 = plugins[p]
        if (entry2 && Util.canonicalWidgetId(String(entry2.id || "")) === wanted)
          return root.copyPluginSettings(entry2)
      }
    }
    return ({})
  }

  function manifestDefaults() {
    if (root.manifest && root.manifest.barWidget
        && root.isPlainRecord(root.manifest.barWidget.defaults))
      return root.manifest.barWidget.defaults
    return ({})
  }

  // Manifest defaults underneath, operator configuration on top.
  readonly property var mergedSettings: {
    var merged = ({})
    var defaults = root.manifestDefaults()
    for (var d in defaults) merged[d] = defaults[d]
    var configured = root.configuredPluginSettings()
    for (var c in configured) merged[c] = configured[c]
    return merged
  }

  function selectSection(key) {
    root.section = key
    root.registerIndex = 0
  }

  function sectionIndex(key) {
    for (var i = 0; i < root.sections.length; i++)
      if (root.sections[i].key === key) return i
    return 0
  }

  function stepSection(delta) {
    var next = root.sectionIndex(root.section) + delta
    if (next < 0) next = root.sections.length - 1
    if (next >= root.sections.length) next = 0
    root.selectSection(root.sections[next].key)
  }

  // Overlay lifecycle contract. The shell's plugin Loader hands the summon
  // payload to open(); isOpen() then reads back `opened`. Without these the
  // surface loads, reports nothing, and never paints.
  function open(payloadJson) {
    root.opened = true
    root.hoverNav = ""
    jackal.refreshIfStale()
    jackal.readInventory()
    jackal.readResults()
    jackal.readNonClaim()
    // Mission control should not open on an empty instrument. This is a sweep
    // of the sealed evaluator like any other — still non-evidentiary, still
    // labelled as such on the canvas.
    if (jackal.graphPoints.length === 0 && !jackal.graphBusy)
      jackal.plotGraph(jackal.graphExpression, jackal.graphXMin, jackal.graphXMax)
  }

  function close() {
    root.opened = false
    root.hoverNav = ""
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  Service {
    id: jackal
    settings: root.mergedSettings
  }

  // ------------------------------------------------------------------ shared

  component Pill: Rectangle {
    id: pill
    property string label: ""
    property color tone: root.telemetry
    implicitWidth: pillText.implicitWidth + Style.space(14)
    implicitHeight: pillText.implicitHeight + Style.space(8)
    radius: Style.space(3)
    color: Qt.alpha(pill.tone, 0.10)
    border.width: 1
    border.color: Qt.alpha(pill.tone, 0.42)
    Text {
      id: pillText
      anchors.centerIn: parent
      text: pill.label
      color: pill.tone
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.1
    }
  }

  component DeckTitle: RowLayout {
    id: deckTitle
    property string title: ""
    property string note: ""
    spacing: Style.space(10)
    Text {
      text: deckTitle.title
      color: root.telemetry
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.5
    }
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: root.hairline
    }
    Text {
      visible: deckTitle.note !== ""
      text: deckTitle.note
      color: root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  component Stat: Rectangle {
    id: stat
    property string label: ""
    property string value: ""
    property color tone: root.signal
    Layout.fillWidth: true
    implicitHeight: statCol.implicitHeight + 2 * Style.space(12)
    color: root.panelRaised
    radius: Style.space(4)
    border.width: 1
    border.color: root.hairline
    ColumnLayout {
      id: statCol
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(4)
      Text {
        text: stat.label
        color: root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1.2
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
      Text {
        text: stat.value
        color: stat.tone
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
    }
  }

  component KeyValue: RowLayout {
    id: kv
    property string label: ""
    property string value: ""
    property color tone: root.dim
    spacing: Style.space(10)
    Text {
      text: kv.label
      color: root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      Layout.preferredWidth: Style.space(150)
    }
    Text {
      text: kv.value
      color: kv.tone
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      Layout.fillWidth: true
      elide: Text.ElideRight
    }
  }

  // ------------------------------------------------------------------ window

  PanelWindow {
    id: cockpitWindow
    visible: root.opened
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "jackal-cockpit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened
      ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      id: scrim
      anchors.fill: parent
      color: Qt.alpha(root.panelVoid, 0.965)
      focus: root.opened

      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
          root.dismiss(); event.accepted = true; return
        }
        if (event.key === Qt.Key_Tab) {
          root.stepSection(1); event.accepted = true; return
        }
        if (event.key === Qt.Key_Backtab) {
          root.stepSection(-1); event.accepted = true; return
        }
        // Actions take Shift so they cannot collide with section letters.
        // R and V would otherwise mean two different things on one key.
        if (event.modifiers & Qt.ShiftModifier) {
          if (event.key === Qt.Key_R) { jackal.refresh(); event.accepted = true }
          else if (event.key === Qt.Key_V) { jackal.verifyArtifact(); event.accepted = true }
          else if (event.key === Qt.Key_C) {
            jackal.copyText(jackal.packageSha, "package digest"); event.accepted = true
          }
          else if (event.key === Qt.Key_N) {
            jackal.copyText(jackal.nonClaim, "non-claim"); event.accepted = true
          }
          if (event.accepted) return
        }
        if (event.key === Qt.Key_O) { root.selectSection("overview"); event.accepted = true }
        else if (event.key === Qt.Key_G) { root.selectSection("graph"); event.accepted = true }
        else if (event.key === Qt.Key_P) { root.selectSection("probes"); event.accepted = true }
        else if (event.key === Qt.Key_L) { root.selectSection("ledger"); event.accepted = true }
        else if (event.key === Qt.Key_V) { root.selectSection("verify"); event.accepted = true }
        else if (event.key === Qt.Key_T) { root.selectSection("thoth"); event.accepted = true }
        else if (event.key === Qt.Key_R) { root.selectSection("register"); event.accepted = true }
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Style.space(18)
        spacing: Style.space(18)

        // ----------------------------------------------------------- nav rail
        Rectangle {
          Layout.preferredWidth: Style.space(214)
          Layout.fillHeight: true
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(6)

            Text {
              text: "JACKAL"
              color: root.signal
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              font.letterSpacing: 3.0
            }
            Text {
              text: "+ THOTH"
              color: root.reentry
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 2.2
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.topMargin: Style.space(8)
              Layout.bottomMargin: Style.space(6)
              Layout.preferredHeight: Style.space(2)
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.reentry }
                GradientStop { position: 0.62; color: root.telemetry }
                GradientStop { position: 1.0; color: root.reentry }
              }
            }

            Repeater {
              model: root.sections
              delegate: Rectangle {
                id: navItem
                required property var modelData
                readonly property bool active: root.section === navItem.modelData.key
                readonly property bool hovered: root.hoverNav === navItem.modelData.key
                Layout.fillWidth: true
                implicitHeight: navCol.implicitHeight + Style.space(16)
                radius: Style.space(3)
                color: navItem.active
                  ? Qt.alpha(root.reentry, 0.13)
                  : (navItem.hovered ? Qt.alpha(root.frost, 0.05) : "transparent")
                border.width: 1
                border.color: navItem.active
                  ? Qt.alpha(root.reentry, 0.55) : "transparent"

                ColumnLayout {
                  id: navCol
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(11)
                  anchors.rightMargin: Style.space(9)
                  spacing: Style.space(2)
                  Text {
                    text: (navItem.active ? "▸ " : "  ") + navItem.modelData.label
                    color: navItem.active ? root.signal : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 1.4
                  }
                  Text {
                    text: "   " + navItem.modelData.hint
                    color: root.faint
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.hoverNav = navItem.modelData.key
                  onExited: {
                    if (root.hoverNav === navItem.modelData.key) root.hoverNav = ""
                  }
                  onClicked: root.selectSection(navItem.modelData.key)
                }
              }
            }

            Item { Layout.fillHeight: true }

            Pill {
              label: jackal.busy ? "PROBING…" : Model.stateLabel(root.evidenceState)
              tone: jackal.busy ? root.reentry : root.stateColor
            }
            Text {
              text: "probed " + root.ageText
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Text {
              text: "Tab · O G P L V T R · Shift+R probe · Shift+V verify · Esc closes"
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
          }
        }

        // -------------------------------------------------------------- main
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: Style.space(14)

          // header
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 2 * Style.space(16)
            color: root.panelSurface
            radius: Style.space(5)
            border.width: 1
            border.color: root.hairline

            RowLayout {
              id: headerRow
              anchors.fill: parent
              anchors.margins: Style.space(16)
              spacing: Style.space(16)

              ColumnLayout {
                spacing: Style.space(3)
                Text {
                  text: "MISSION CONTROL"
                  color: root.signal
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  font.letterSpacing: 2.6
                }
                Text {
                  text: "THOTH lives inside JACKAL — one engine, one identity."
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              Item { Layout.fillWidth: true }

              Pill {
                label: jackal.probePassed + "/" + jackal.probeTotal + " FUNCTION"
                tone: jackal.probeTotal > 0 && jackal.probePassed === jackal.probeTotal
                  ? root.signal : root.reentry
              }
              Pill {
                label: jackal.epoch !== "" ? "RUNTIME " + jackal.epoch : "RUNTIME —"
                tone: root.telemetry
              }
              Pill {
                label: jackal.identityMatch ? "IDENTITY MATCH" : "IDENTITY UNPROVEN"
                tone: jackal.identityMatch ? root.signal : root.reentry
              }

              Rectangle {
                implicitWidth: Style.space(30)
                implicitHeight: Style.space(30)
                radius: Style.space(3)
                color: closeArea.containsMouse
                  ? Qt.alpha(root.reentry, 0.18) : "transparent"
                border.width: 1
                border.color: Qt.alpha(root.reentry, 0.45)
                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  color: root.reentry
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                MouseArea {
                  id: closeArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.dismiss()
                }
              }
            }
          }

          // canvas
          StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.sectionIndex(root.section)

            OverviewSection {}
            GraphSection {}
            ProbesSection {}
            LedgerSection {}
            VerifySection {}
            ThothSection {}
            RegisterSection {}
          }

          // pinned laws — never inside a scroll area
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: lawsCol.implicitHeight + 2 * Style.space(14)
            color: root.panelSurface
            radius: Style.space(5)
            border.width: 1
            border.color: Qt.alpha(root.reentry, 0.30)

            ColumnLayout {
              id: lawsCol
              anchors.fill: parent
              anchors.margins: Style.space(14)
              spacing: Style.space(5)

              RowLayout {
                spacing: Style.space(10)
                Text {
                  text: "ASSURANCE ≠ CONSEQUENCE"
                  color: root.reentry
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1.4
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }
                Text {
                  text: "A ceiling is an upper bound, never a grant."
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
              Text {
                text: "Refusal is a first-class answer. A refused question is answered — "
                  + "it is not retried on a weaker lane to obtain some number."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
              }
              Text {
                visible: jackal.nonClaim !== ""
                text: "NON-CLAIM · " + jackal.nonClaim
                color: root.telemetry
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
              }
            }
          }
        }
      }
    }
  }

  // The newest ledger entry, carried at card weight. Ported from the dropdown
  // so the account survives the panel becoming a pill: it is recall, and it
  // says so on its face rather than implying the answer was re-verified.
  component LatestAnswerCard: Rectangle {
    id: latestCard
    property var row: null
    readonly property color tone:
      latestCard.row && latestCard.row.refused ? root.dim : root.telemetry

    implicitHeight: latestContent.height + 2 * Style.space(11)
    radius: Style.space(4)
    color: root.panelSurface
    border.color: Qt.alpha(latestCard.tone, 0.52)
    border.width: 1
    clip: true

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: Style.space(3)
      color: latestCard.tone
    }

    Column {
      id: latestContent
      x: Style.space(13)
      y: Style.space(11)
      width: Math.max(0, latestCard.width - Style.space(13) - Style.space(11))
      spacing: Style.space(4)

      Row {
        width: parent.width
        spacing: Style.space(8)
        Text {
          id: latestTitle
          text: "LATEST ANSWER  /  LOCAL RECALL"
          color: root.telemetry
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.4
        }
        Item {
          width: Math.max(0, parent.width - latestTitle.width
            - latestStatus.width - 2 * parent.spacing)
          height: 1
        }
        Pill {
          id: latestStatus
          visible: latestCard.row !== null
          label: latestCard.row ? String(latestCard.row.status || "") : ""
          tone: latestCard.tone
        }
      }

      Text {
        width: parent.width
        text: latestCard.row ? String(latestCard.row.tool || "")
          : "No recorded answer yet"
        color: root.frost
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        visible: latestCard.row ? String(latestCard.row.request || "") !== "" : false
        height: visible ? implicitHeight : 0
        width: parent.width
        text: latestCard.row ? String(latestCard.row.request || "") : ""
        color: root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: latestCard.row
          ? (String(latestCard.row.detail || "") !== ""
             ? String(latestCard.row.detail) : "No result detail recorded.")
          : "The newest ledger entry appears here without opening a section."
        color: latestCard.row && latestCard.row.refused ? root.dim : root.frost
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      Row {
        visible: latestCard.row !== null
        height: visible ? implicitHeight : 0
        width: parent.width
        spacing: Style.space(8)
        Text {
          id: latestAge
          text: latestCard.row
            ? Model.ageText(latestCard.row.atMs, jackal.nowMs) : ""
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Item {
          width: Math.max(0, parent.width - latestAge.width
            - latestRecallNote.width - 2 * parent.spacing)
          height: 1
        }
        Text {
          id: latestRecallNote
          text: "recall only · not re-verified"
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  // --------------------------------------------------------- OVERVIEW section
  // The bird's-eye view: every account visible at once, none of them merged.
  // Each tile is a window onto the same data the dedicated section shows in
  // full — never a summary score, and never a promoted claim.

  component OverviewSection: Item {
    RowLayout {
      anchors.fill: parent
      spacing: Style.space(12)

      // ---- left: the instrument, and what it has actually returned --------
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1000
        spacing: Style.space(12)

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredHeight: 600
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(10)

            DeckTitle {
              Layout.fillWidth: true
              title: "GRAPH DECK — LIVE SWEEP"
              note: "graph pixels are visualization, never evidence"
            }
            SweepPlot {
              Layout.fillWidth: true
              Layout.fillHeight: true
            }
            Text {
              Layout.fillWidth: true
              text: jackal.graphExpression + "   x ∈ [" + jackal.graphXMin
                + ", " + jackal.graphXMax + "]"
                + (jackal.graphMeta !== "" ? "   ·   " + jackal.graphMeta : "")
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredHeight: 380
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(10)

            DeckTitle {
              Layout.fillWidth: true
              title: "LATEST RESULTS"
              note: "recall, not evidence"
            }

            Flickable {
              id: ovLedgerFlick
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentWidth: width
              contentHeight: ovLedgerCol.height
              clip: true
              pixelAligned: true
              interactive: contentHeight > height

              Column {
                id: ovLedgerCol
                width: ovLedgerFlick.width
                spacing: Style.space(4)

                Text {
                  visible: jackal.results.length === 0
                  text: "no recorded results yet"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Repeater {
                  model: jackal.results
                  delegate: Rectangle {
                    id: ovRes
                    required property var modelData
                    // parseResults() already applied resultRow() to every
                    // entry, so these ARE rows. Transforming again dropped
                    // detail and atMs while status/tool survived.
                    readonly property var row: ovRes.modelData
                    width: ovLedgerCol.width
                    height: ovResCol.height + 2 * Style.space(9)
                    radius: Style.space(3)
                    color: root.panelRaised
                    border.width: 1
                    border.color: root.hairline

                    Column {
                      id: ovResCol
                      x: Style.space(10)
                      y: Style.space(9)
                      width: ovRes.width - 2 * Style.space(10)
                      spacing: Style.space(4)

                      Row {
                        spacing: Style.space(9)
                        Pill {
                          label: String(ovRes.row.status || "—")
                          tone: ovRes.row.refused ? root.reentry : root.telemetry
                        }
                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          text: String(ovRes.row.tool || "")
                          color: root.signal
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                        }
                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          text: Model.ageText(ovRes.row.atMs, jackal.nowMs)
                          color: root.faint
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                        }
                      }

                      // A full-width line of its own rather than a share of the
                      // header row: the answer is the point of the entry, and
                      // sizing it against its siblings collapsed it to nothing.
                      Text {
                        width: parent.width
                        text: String(ovRes.row.detail || "")
                        color: ovRes.row.refused ? root.reentry : root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // ---- right: the accounts that bound what any of it may decide -------
      ColumnLayout {
        Layout.fillHeight: true
        Layout.preferredWidth: 620
        spacing: Style.space(12)

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: ovFn.implicitHeight + 2 * Style.space(14)
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            id: ovFn
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(9)

            DeckTitle {
              Layout.fillWidth: true
              title: "SESSION FUNCTION"
              note: "this shell session only"
            }
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(10)
              Pill {
                label: jackal.probePassed + " / " + jackal.probeTotal + " PROBES"
                tone: jackal.probeTotal > 0
                  && jackal.probePassed === jackal.probeTotal
                  ? root.signal : root.reentry
              }
              Pill {
                label: jackal.verdict !== "" ? jackal.verdict.toUpperCase() : "NO VERDICT"
                tone: root.stateColor
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "probed " + root.ageText
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: ovRt.implicitHeight + 2 * Style.space(14)
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            id: ovRt
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(7)

            DeckTitle {
              Layout.fillWidth: true
              title: "SEALED RUNTIME · THOTH"
              note: "one engine, one identity"
            }
            KeyValue {
              Layout.fillWidth: true
              label: "EPOCH"
              value: jackal.epoch !== "" ? jackal.epoch : "—"
              tone: root.telemetry
            }
            KeyValue {
              Layout.fillWidth: true
              label: "IDENTITY"
              value: jackal.identityMatch ? "match" : "unproven"
              tone: jackal.identityMatch ? root.signal : root.reentry
            }
            KeyValue {
              Layout.fillWidth: true
              label: "DECLARED TOOLS"
              value: String(jackal.declaredToolCount)
            }
            KeyValue {
              Layout.fillWidth: true
              label: "CATALOG SHA"
              value: jackal.catalogSha !== ""
                ? Model.shortHash(jackal.catalogSha) : "—"
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(9)

            DeckTitle {
              Layout.fillWidth: true
              title: "EVIDENCE REGISTER"
              note: "both axes, never merged"
            }

            Flickable {
              id: ovRegFlick
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentWidth: width
              contentHeight: ovRegCol.height
              clip: true
              pixelAligned: true
              interactive: contentHeight > height

              Column {
                id: ovRegCol
                width: ovRegFlick.width
                spacing: Style.space(3)

                Text {
                  visible: jackal.familyRows.length === 0
                  text: "capability inventory not loaded"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Repeater {
                  model: jackal.familyRows
                  delegate: Item {
                    id: ovFam
                    required property var modelData
                    width: ovRegCol.width
                    height: ovFamRow.height + Style.space(8)

                    Row {
                      id: ovFamRow
                      width: ovFam.width
                      spacing: Style.space(8)

                      Text {
                        width: Math.round(ovFam.width * 0.34)
                        text: String(ovFam.modelData.family || "")
                        color: root.signal
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                      }
                      Text {
                        width: Math.round(ovFam.width * 0.32)
                        text: String(ovFam.modelData.assurance || "—")
                        color: root.telemetry
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                      }
                      Text {
                        width: Math.round(ovFam.width * 0.30)
                        text: String(ovFam.modelData.consequence || "—")
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                      }
                    }
                  }
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: ovVf.implicitHeight + 2 * Style.space(14)
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: Qt.alpha(root.reentry, 0.28)

          ColumnLayout {
            id: ovVf
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(9)

            DeckTitle {
              Layout.fillWidth: true
              title: "VERIFY"
              note: "the one lane that acts"
            }
            Text {
              Layout.fillWidth: true
              text: jackal.verifyResult
                ? Model.verifyStatusLabel(jackal.verifyResult.status)
                : (jackal.actionStatus !== "" ? jackal.actionStatus
                   : "no artifact routed yet")
              color: jackal.verifyResult
                && Model.verifyIsAlarming(jackal.verifyResult)
                ? root.reentry : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }

  // The sweep instrument, extracted so the overview and the dedicated
  // GRAPH section render the identical canvas rather than two drifting
  // copies of the same paint code.
  component SweepPlot: Rectangle {
    id: plotFrame
    color: "#0d0e11"
    radius: Style.space(3)
    border.width: 1
    border.color: root.hairline
    clip: true

    Text {
      anchors.centerIn: parent
      visible: jackal.graphPoints.length === 0 && !jackal.graphBusy
      text: jackal.graphError !== ""
        ? jackal.graphError
        : "no sweep yet — enter an expression and press SWEEP"
      color: jackal.graphError !== "" ? root.reentry : root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      width: plotFrame.width - Style.space(40)
      wrapMode: Text.WordWrap
    }

    Canvas {
      id: graphCanvas
      anchors.fill: parent
      anchors.margins: Style.space(2)
      visible: jackal.graphPoints.length > 0

      property var points: jackal.graphPoints
      property real hoverX: -1
      property bool hovering: false

      onPointsChanged: graphCanvas.requestPaint()
      onWidthChanged: graphCanvas.requestPaint()
      onHeightChanged: graphCanvas.requestPaint()

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function (mouse) {
          graphCanvas.hoverX = mouse.x
          graphCanvas.hovering = true
          graphCanvas.requestPaint()
        }
        onExited: {
          graphCanvas.hovering = false
          graphCanvas.requestPaint()
        }
      }

onPaint: {
        // Contracts this paint honours, all from Model.js:
        //   point        { x, y }  with y === null meaning REFUSED
        //   graphExtremes -> { min: {x,y}, max: {x,y} }  (may be null/null)
        //   graphRefusedRuns -> [{ x0, x1 }] in X-DOMAIN units, not indices
        var ctx = graphCanvas.getContext("2d")
        ctx.reset()
        var w = graphCanvas.width
        var h = graphCanvas.height
        var pts = graphCanvas.points
        if (!pts || pts.length === 0) return
      
        var tickFont = Style.font.caption + "px " + root.fontFamily
        ctx.font = tickFont
      
        var ext = Model.graphExtremes(pts)
        // A refusal is an answer. If every sample refused there is nothing to
        // plot, and the canvas says that rather than drawing an empty grid.
        if (!ext || !ext.min || !ext.max) {
          ctx.fillStyle = Qt.alpha(root.telemetry, 0.85)
          var refusedText = "every sample refused — nothing to plot"
          ctx.fillText(refusedText, (w - ctx.measureText(refusedText).width) / 2, h / 2)
          return
        }
      
        var yMin = ext.min.y
        var yMax = ext.max.y
        if (!(yMax > yMin)) { yMax = yMin + 1; yMin = yMin - 1 }
        var xLo = pts[0].x
        var xHi = pts[pts.length - 1].x
      
        var yTicks = Model.graphTicks(yMin, yMax, 6)
        var gutterL = 8
        for (var yl = 0; yl < yTicks.ticks.length; yl++) {
          var cand = ctx.measureText(
            Model.graphTickLabel(yTicks.ticks[yl], yTicks.step)).width
          if (cand + 14 > gutterL) gutterL = cand + 14
        }
        var top = 12
        var bottom = 26
        var plotW = Math.max(10, w - gutterL - 14)
        var plotH = Math.max(10, h - top - bottom)
      
        function sx(xv) {
          return gutterL + (xHi === xLo ? 0 : ((xv - xLo) / (xHi - xLo)) * plotW)
        }
        function sy(v) {
          return top + plotH - ((v - yMin) / (yMax - yMin)) * plotH
        }
      
        ctx.fillStyle = "#0d0e11"
        ctx.fillRect(gutterL, top, plotW, plotH)
      
        // Refused spans are painted, never silently skipped.
        var runs = Model.graphRefusedRuns(pts)
        ctx.fillStyle = Qt.alpha(root.reentry, 0.12)
        for (var r = 0; r < runs.length; r++) {
          var bx0 = sx(runs[r].x0)
          var bx1 = sx(runs[r].x1)
          ctx.fillRect(bx0, top, Math.max(1, bx1 - bx0), plotH)
        }
      
        ctx.strokeStyle = Qt.alpha(root.telemetry, 0.13)
        ctx.lineWidth = 1
        ctx.fillStyle = Qt.alpha(root.telemetry, 0.62)
        for (var t = 0; t < yTicks.ticks.length; t++) {
          var yv = yTicks.ticks[t]
          if (yv < yMin || yv > yMax) continue
          var yy = sy(yv)
          ctx.beginPath()
          ctx.moveTo(gutterL, yy)
          ctx.lineTo(gutterL + plotW, yy)
          ctx.stroke()
          var lbl = Model.graphTickLabel(yv, yTicks.step)
          ctx.fillText(lbl, gutterL - ctx.measureText(lbl).width - 6, yy + 3)
        }
      
        if (yMin < 0 && yMax > 0) {
          ctx.strokeStyle = Qt.alpha(root.telemetry, 0.34)
          ctx.beginPath()
          ctx.moveTo(gutterL, sy(0))
          ctx.lineTo(gutterL + plotW, sy(0))
          ctx.stroke()
        }
      
        // The curve. A refused sample lifts the pen: the line is never drawn
        // across a gap the evaluator declined to answer.
        ctx.strokeStyle = root.reentry
        ctx.lineWidth = 2
        ctx.beginPath()
        var drawing = false
        for (var i = 0; i < pts.length; i++) {
          var pt = pts[i]
          if (!pt || pt.y === null || !isFinite(pt.y)) { drawing = false; continue }
          if (!drawing) { ctx.moveTo(sx(pt.x), sy(pt.y)); drawing = true }
          else ctx.lineTo(sx(pt.x), sy(pt.y))
        }
        ctx.stroke()
      
        ctx.fillStyle = Qt.alpha(root.telemetry, 0.62)
        var loText = Model.graphNumberText(xLo)
        var hiText = Model.graphNumberText(xHi)
        ctx.fillText(loText, gutterL, top + plotH + 16)
        ctx.fillText(hiText, gutterL + plotW - ctx.measureText(hiText).width,
          top + plotH + 16)
      
        if (graphCanvas.hovering && pts.length > 1) {
          var rel = Math.min(1, Math.max(0, (graphCanvas.hoverX - gutterL) / plotW))
          var idx = Math.round(rel * (pts.length - 1))
          var hp = pts[idx]
          var hx = sx(hp.x)
          ctx.strokeStyle = Qt.alpha(root.frost, 0.35)
          ctx.lineWidth = 1
          ctx.beginPath()
          ctx.moveTo(hx, top)
          ctx.lineTo(hx, top + plotH)
          ctx.stroke()
          if (hp.y !== null && isFinite(hp.y)) {
            ctx.fillStyle = root.frost
            ctx.beginPath()
            ctx.arc(hx, sy(hp.y), 3, 0, Math.PI * 2)
            ctx.fill()
          }
          var ht = Model.graphHoverText(hp, idx, pts.length)
          ctx.fillStyle = root.frost
          var tw = ctx.measureText(ht).width
          var tx = Math.min(gutterL + plotW - tw, Math.max(gutterL, hx + 8))
          ctx.fillText(ht, tx, top + 12)
        }
      }
    }
  }


  // ------------------------------------------------------------ GRAPH section

  component GraphSection: Item {
    id: graphSection

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.space(12)

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.space(12)

        // primary: live sweep
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(10)

            DeckTitle {
              Layout.fillWidth: true
              title: "GRAPH DECK — LIVE SWEEP"
              note: "graph pixels are visualization, never evidence"
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(10)
              Pill {
                label: jackal.graphBusy ? "SWEEPING…" : "SEALED EVALUATOR · f64"
                tone: jackal.graphBusy ? root.reentry : root.signal
              }
              Text {
                text: jackal.graphMeta
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }

            SweepPlot {
              Layout.fillWidth: true
              Layout.fillHeight: true
            }

            Text {
              Layout.fillWidth: true
              text: "Live sweep · status=estimated visualization. Exact rational x grid; "
                    + "f64 samples from the runtime's own evaluator; a refused sample "
                    + "breaks the curve; pixels are not proof."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
              horizontalAlignment: Text.AlignHCenter
            }

            // sweep controls
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(8)

              Text {
                text: "f(x)"
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              TextField {
                id: exprField
                Layout.fillWidth: true
                text: jackal.graphExpression
                placeholderText: "x^6-5*x^4+4*x^2"
                onAccepted: jackal.plotGraph(exprField.text, loField.text, hiField.text)
              }
              Text {
                text: "lo"
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              TextField {
                id: loField
                Layout.preferredWidth: Style.space(90)
                text: jackal.graphXMin
                onAccepted: jackal.plotGraph(exprField.text, loField.text, hiField.text)
              }
              Text {
                text: "hi"
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              TextField {
                id: hiField
                Layout.preferredWidth: Style.space(90)
                text: jackal.graphXMax
                onAccepted: jackal.plotGraph(exprField.text, loField.text, hiField.text)
              }
              Rectangle {
                implicitWidth: sweepText.implicitWidth + Style.space(22)
                implicitHeight: sweepText.implicitHeight + Style.space(12)
                radius: Style.space(3)
                color: jackal.graphBusy
                  ? Qt.alpha(root.telemetry, 0.10)
                  : (sweepArea.containsMouse
                     ? Qt.alpha(root.reentry, 0.22) : Qt.alpha(root.reentry, 0.12))
                border.width: 1
                border.color: Qt.alpha(root.reentry, 0.55)
                Text {
                  id: sweepText
                  anchors.centerIn: parent
                  text: jackal.graphBusy ? "SWEEPING…" : "▸ SWEEP"
                  color: jackal.graphBusy ? root.faint : root.reentry
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1.2
                }
                MouseArea {
                  id: sweepArea
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: !jackal.graphBusy
                  cursorShape: Qt.PointingHandCursor
                  onClicked: jackal.plotGraph(exprField.text, loField.text, hiField.text)
                }
              }
            }
          }
        }

        // secondary: THOTH / HELLGATE reference render
        Rectangle {
          Layout.preferredWidth: Style.space(300)
          Layout.fillHeight: true
          color: root.panelSurface
          radius: Style.space(5)
          border.width: 1
          border.color: root.hairline

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.space(14)
            spacing: Style.space(10)

            DeckTitle {
              Layout.fillWidth: true
              title: "THOTH · HELLGATE"
              note: "reference render"
            }

            Image {
              Layout.fillWidth: true
              Layout.preferredHeight: width * 0.62
              source: Qt.resolvedUrl("assets/jackal-thoth-hellgate-graph.png")
              fillMode: Image.PreserveAspectFit
              smooth: true
              asynchronous: true
            }

            Text {
              Layout.fillWidth: true
              text: "The HELLGATE lane returns bounded, not formal-bounded. "
                + "This render is a picture of a result, not the result."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

            Text {
              Layout.fillWidth: true
              text: "PRESETS"
              color: root.telemetry
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.4
            }

            Repeater {
              model: [
                { label: "sextic well", expr: "x^6-5*x^4+4*x^2", lo: "-2.6", hi: "2.6" },
                { label: "damped wave", expr: "sin(x)/x", lo: "-18", hi: "18" },
                { label: "gaussian", expr: "exp(-x^2)", lo: "-3", hi: "3" },
                { label: "tanh gate", expr: "tanh(x)", lo: "-4", hi: "4" }
              ]
              delegate: Rectangle {
                id: presetRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: presetText.implicitHeight + 2 * Style.space(10)
                radius: Style.space(3)
                color: presetArea.containsMouse
                  ? Qt.alpha(root.frost, 0.06) : "transparent"
                border.width: 1
                border.color: root.hairline
                Text {
                  id: presetText
                  anchors.fill: parent
                  anchors.margins: Style.space(10)
                  text: presetRow.modelData.label + "  ·  " + presetRow.modelData.expr
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
                MouseArea {
                  id: presetArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    exprField.text = presetRow.modelData.expr
                    loField.text = presetRow.modelData.lo
                    hiField.text = presetRow.modelData.hi
                    jackal.plotGraph(presetRow.modelData.expr,
                      presetRow.modelData.lo, presetRow.modelData.hi)
                  }
                }
              }
            }

            Item { Layout.fillHeight: true }
          }
        }
      }
    }
  }

  // ----------------------------------------------------------- PROBES section

  component ProbesSection: Item {
    Rectangle {
      anchors.fill: parent
      color: root.panelSurface
      radius: Style.space(5)
      border.width: 1
      border.color: root.hairline

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        DeckTitle {
          Layout.fillWidth: true
          title: "SESSION FUNCTION — LIVE PROBES"
          note: "established only by tools executed in this shell session"
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)
          Stat {
            label: "PROBES PASSED"
            value: jackal.probePassed + " / " + jackal.probeTotal
            tone: jackal.probeTotal > 0 && jackal.probePassed === jackal.probeTotal
              ? root.signal : root.reentry
          }
          Stat {
            label: "DOCTOR VERDICT"
            value: jackal.verdict !== "" ? jackal.verdict : "—"
            tone: root.stateColor
          }
          Stat {
            label: "Z3"
            value: jackal.z3Present ? "present" : "absent"
            tone: jackal.z3Present ? root.signal : root.dim
          }
          Stat {
            label: "ANUBIS COMPILER"
            value: jackal.anubisPresent ? "present" : "absent"
            tone: jackal.anubisPresent ? root.signal : root.dim
          }
        }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ColumnLayout {
            width: parent.width
            spacing: Style.space(4)
            Repeater {
              model: jackal.probeRows
              delegate: Rectangle {
                id: probeRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: probeLine.implicitHeight + 2 * Style.space(11)
                radius: Style.space(3)
                color: root.panelRaised
                border.width: 1
                border.color: root.hairline
                RowLayout {
                  id: probeLine
                  anchors.fill: parent
                  anchors.margins: Style.space(11)
                  spacing: Style.space(10)
                  Text {
                    text: probeRow.modelData.pass ? "●" : "○"
                    color: probeRow.modelData.pass ? root.signal : root.reentry
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                  Text {
                    text: String(probeRow.modelData.name || "")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text {
                    // executed vs expected, kept apart: the pair is the whole
                    // claim, and collapsing it would hide which side drifted.
                    text: String(probeRow.modelData.executed || "—")
                      + "  /  " + String(probeRow.modelData.expected || "—")
                    color: root.faint
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // ----------------------------------------------------------- LEDGER section

  component LedgerSection: Item {
    Rectangle {
      anchors.fill: parent
      color: root.panelSurface
      radius: Style.space(5)
      border.width: 1
      border.color: root.hairline

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        DeckTitle {
          Layout.fillWidth: true
          title: "LATEST RESULTS — LOCAL RECALL"
          note: "recall, not evidence — a file this tooling wrote"
        }

        Text {
          Layout.fillWidth: true
          text: "The ledger answers \"did this session actually call JACKAL?\" "
            + "It is never a source. A retained receipt is re-verified through "
            + "the real front door in VERIFY."
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        LatestAnswerCard {
          Layout.fillWidth: true
          row: jackal.results.length > 0 ? jackal.results[0] : null
        }

        // Flickable + plain Column rather than a nested Layout. A Column takes
        // its height FROM its children; a Layout negotiates height WITH them,
        // and when the parent is sized from the layout the negotiation has no
        // slack and wrapped text gets compressed onto the row above it.
        Flickable {
          id: ledgerFlick
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentWidth: width
          contentHeight: ledgerColumn.height
          clip: true
          pixelAligned: true
          interactive: contentHeight > height
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Rectangle {
            id: readingPlaneBackground
            width: ledgerFlick.width
            height: ledgerColumn.height
            color: root.panelVoid
            z: -1
          }

          Column {
            id: ledgerColumn
            width: ledgerFlick.width
            spacing: Style.space(6)
            // Render the complete reading surface as one opaque device-pixel
            // layer. Text no longer re-composites independently against moving
            // translucent decoration while the viewport scrolls.
            layer.enabled: true
            layer.smooth: false
            layer.mipmap: false

            Text {
              visible: jackal.results.length === 0
              text: "no recorded results yet"
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Repeater {
              model: jackal.results
              delegate: Rectangle {
                id: resRow
                required property var modelData
                readonly property var row: resRow.modelData
                width: ledgerColumn.width
                height: resCol.height + 2 * Style.space(12)
                radius: Style.space(4)
                color: root.panelRaised
                border.width: 1
                border.color: root.hairline

                Column {
                  id: resCol
                  x: Style.space(12)
                  y: Style.space(12)
                  width: resRow.width - 2 * Style.space(12)
                  spacing: Style.space(5)

                  Row {
                    spacing: Style.space(10)

                    Pill {
                      label: String(resRow.row.status || "—")
                      tone: String(resRow.row.status || "") === "refused"
                        ? root.reentry : root.telemetry
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: String(resRow.row.tool || "")
                      color: root.signal
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: Model.ageText(resRow.row.atMs, jackal.nowMs)
                      color: root.faint
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                    // A digest names a receipt that can be re-verified through
                    // a front door. Without retention it names evidence that no
                    // longer exists, so the two are shown separately.
                    Pill {
                      visible: resRow.row.digest !== ""
                      label: resRow.row.retained ? "RECEIPT RETAINED" : "RECEIPT GONE"
                      tone: resRow.row.retained ? root.telemetry : root.reentry
                    }
                  }

                  // resultRow() already resolved refusal-vs-answer. Rendering
                  // the refusal lane unconditionally would paint every ordinary
                  // answer in refusal crimson — the exact promotion JOP-UI-001
                  // forbids — because that helper always returns a string.
                  Text {
                    width: parent.width
                    visible: String(resRow.row.request || "") !== ""
                    height: visible ? implicitHeight : 0
                    text: String(resRow.row.request || "")
                    color: root.faint
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                  Text {
                    width: parent.width
                    text: String(resRow.row.detail || "")
                    color: resRow.row.refused ? root.reentry : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // ----------------------------------------------------------- VERIFY section

  component VerifySection: Item {
    Rectangle {
      anchors.fill: parent
      color: root.panelSurface
      radius: Style.space(5)
      border.width: 1
      border.color: Qt.alpha(root.reentry, 0.28)

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        DeckTitle {
          Layout.fillWidth: true
          title: "VERIFY — CLIPBOARD ARTIFACT"
          note: "the one section that acts"
        }

        Text {
          Layout.fillWidth: true
          text: "Expectations come from the operator's file, "
            + "never from the artifact under review. "
            + "If verification refuses because the expectations do not "
            + "authorize that request, that is correct — widening the "
            + "authorization is a deliberate operator edit, never something "
            + "done to make a check pass."
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)

          Rectangle {
            implicitWidth: verifyText.implicitWidth + Style.space(26)
            implicitHeight: verifyText.implicitHeight + Style.space(14)
            radius: Style.space(3)
            color: jackal.verifyBusy
              ? Qt.alpha(root.telemetry, 0.10)
              : (verifyArea.containsMouse
                 ? Qt.alpha(root.reentry, 0.22) : Qt.alpha(root.reentry, 0.12))
            border.width: 1
            border.color: Qt.alpha(root.reentry, 0.55)
            Text {
              id: verifyText
              anchors.centerIn: parent
              text: jackal.verifyBusy ? "VERIFYING…" : "▸ VERIFY CLIPBOARD ARTIFACT"
              color: jackal.verifyBusy ? root.faint : root.reentry
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
            }
            MouseArea {
              id: verifyArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: !jackal.verifyBusy
              cursorShape: Qt.PointingHandCursor
              onClicked: jackal.verifyArtifact()
            }
          }

          Item { Layout.fillWidth: true }

          Pill {
            label: "RUNTIME " + (jackal.runtimePath !== "" ? "BOUND" : "UNBOUND")
            tone: jackal.runtimePath !== "" ? root.signal : root.dim
          }
        }

        KeyValue {
          Layout.fillWidth: true
          label: "AUTHORIZED BY YOU"
          value: jackal.expectationsPath !== "" ? jackal.expectationsPath : "—"
        }
        KeyValue {
          Layout.fillWidth: true
          label: "RUNTIME VERIFY"
          value: jackal.verifyText !== "" ? jackal.verifyText : "—"
          tone: root.stateColor
        }
        KeyValue {
          Layout.fillWidth: true
          label: "RUNTIME PATH"
          value: jackal.runtimePath !== "" ? jackal.runtimePath : "—"
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ColumnLayout {
            width: parent.width
            spacing: Style.space(6)

            Text {
              visible: !jackal.verifyResult
              text: jackal.actionStatus !== ""
                ? jackal.actionStatus
                : "no artifact routed yet — copy a receipt or bundle, then VERIFY"
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }

            Text {
              visible: !!jackal.verifyResult
              text: Model.verifyStatusLabel(
                jackal.verifyResult ? jackal.verifyResult.status : "")
              color: jackal.verifyResult
                && Model.verifyIsAlarming(jackal.verifyResult)
                ? root.reentry : root.signal
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              visible: !!jackal.verifyResult
              Layout.fillWidth: true
              text: Model.verifySubject(jackal.verifyResult)
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
            Text {
              visible: !!jackal.verifyResult
                && Model.verifyRaisedByText(jackal.verifyResult) !== ""
              Layout.fillWidth: true
              text: Model.verifyRaisedByText(jackal.verifyResult)
              color: root.reentry
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }

  // ------------------------------------------------------------ THOTH section

  component ThothSection: Item {
    Rectangle {
      anchors.fill: parent
      color: root.panelSurface
      radius: Style.space(5)
      border.width: 1
      border.color: root.hairline

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        DeckTitle {
          Layout.fillWidth: true
          title: "INTEGRATED THOTH — SEALED RUNTIME"
          note: "one engine, one identity"
        }

        Text {
          Layout.fillWidth: true
          text: "THOTH lives inside JACKAL as its identity-pinned "
            + "measurement/provenance subsystem — not a separate service. "
            + "Exact-given remains conditional on its given datum."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)
          Stat {
            label: "RUNTIME EPOCH"
            value: jackal.epoch !== "" ? jackal.epoch : "—"
            tone: root.telemetry
          }
          Stat {
            label: "IDENTITY"
            value: jackal.identityMatch ? "match" : "unproven"
            tone: jackal.identityMatch ? root.signal : root.reentry
          }
          Stat {
            label: "DECLARED TOOLS"
            value: String(jackal.declaredToolCount)
            tone: root.signal
          }
          Stat {
            label: "UNIFIED SURFACE"
            value: "74 tools"
            tone: root.reentry
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)
          Stat {
            label: "STEM WORKFLOWS"
            value: "7 linked engineering tools"
            tone: root.telemetry
          }
          Stat {
            label: "NUMBER THEORY"
            value: "10 certified Diophantine tools"
            tone: root.signal
          }
          Stat {
            label: "ENGINEERING"
            value: "6 certified STEM models"
            tone: root.signal
          }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

        KeyValue {
          Layout.fillWidth: true
          label: "PACKAGE SHA"
          value: jackal.packageSha !== "" ? jackal.packageSha : "—"
        }
        KeyValue {
          Layout.fillWidth: true
          label: "CATALOG SHA"
          value: jackal.catalogSha !== "" ? jackal.catalogSha : "—"
        }
        KeyValue {
          Layout.fillWidth: true
          label: "DOCTOR RUNTIME"
          value: jackal.doctorRuntimePath !== "" ? jackal.doctorRuntimePath : "—"
        }
        KeyValue {
          Layout.fillWidth: true
          label: "HOST"
          value: jackal.hostText !== "" ? jackal.hostText : "—"
        }
        KeyValue {
          Layout.fillWidth: true
          label: "EVERY TOOL DECLARES REFUSED"
          value: jackal.everyToolDeclaresRefused ? "yes" : "no"
          tone: jackal.everyToolDeclaresRefused ? root.signal : root.reentry
        }

        Item { Layout.fillHeight: true }
      }
    }
  }

  // --------------------------------------------------------- REGISTER section

  component RegisterSection: Item {
    Rectangle {
      anchors.fill: parent
      color: root.panelSurface
      radius: Style.space(5)
      border.width: 1
      border.color: root.hairline

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        DeckTitle {
          Layout.fillWidth: true
          title: "EVIDENCE REGISTER — CAPABILITY"
          note: "both axes, never merged into a score"
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)
          Text {
            text: "FAMILY"
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            Layout.preferredWidth: Style.space(190)
          }
          Text {
            text: "ASSURANCE"
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            Layout.fillWidth: true
          }
          Text {
            text: "CONSEQUENCE"
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            Layout.fillWidth: true
          }
        }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ColumnLayout {
            width: parent.width
            spacing: Style.space(4)

            Text {
              visible: jackal.familyRows.length === 0
              text: "capability inventory not loaded"
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Repeater {
              model: jackal.familyRows
              delegate: Rectangle {
                id: famRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: famLine.implicitHeight + 2 * Style.space(12)
                radius: Style.space(3)
                color: root.panelRaised
                border.width: 1
                border.color: root.hairline
                RowLayout {
                  id: famLine
                  anchors.fill: parent
                  anchors.margins: Style.space(12)
                  spacing: Style.space(10)
                  Text {
                    text: String(famRow.modelData.family || "")
                    color: root.signal
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    Layout.preferredWidth: Style.space(178)
                    elide: Text.ElideRight
                  }
                  Text {
                    text: String(famRow.modelData.assurance || "—")
                    color: root.telemetry
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text {
                    text: String(famRow.modelData.consequence || "—")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                }
              }
            }

            Item { implicitHeight: Style.space(10) }

            DeckTitle {
              Layout.fillWidth: true
              title: "AGENT SURFACE"
              note: "which tools a profile exposes — the operator's lever"
            }

            Repeater {
              model: jackal.profileRows
              delegate: RowLayout {
                id: profRow
                required property var modelData
                Layout.fillWidth: true
                spacing: Style.space(10)
                Text {
                  text: String(profRow.modelData.name || "")
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  Layout.preferredWidth: Style.space(178)
                  elide: Text.ElideRight
                }
                Text {
                  text: String(profRow.modelData.detail || "")
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }
            }
          }
        }
      }
    }
  }
}
