import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// JACKAL + THOTH in the bar.
//
// JACKAL is a mathematical evidence kernel: every answer declares what kind of
// answer it is, refusal is a first-class answer, and two independent things are
// always stated — how well a fact is established (ASSURANCE) and what may be
// decided on it (CONSEQUENCE). A ceiling is an upper bound, never a grant.
//
// THOTH is JACKAL's integrated measurement/provenance subsystem, not a second
// engine. This widget is built to preserve that architecture and JACKAL's
// assurance boundaries rather than summarise them away, so it keeps these
// accounts strictly apart and never merges them into a score:
//
//   VERIFY             the one section that ACTS. Routes a clipboard receipt or
//                      bundle to a real front door and prints its verdict
//                      verbatim, against an authorization the operator owns —
//                      never one taken from the artifact under review.
//   AGENT SURFACE      which tools a profile exposes. The operator's lever.
//   EVIDENCE REGISTER  capability — what actually stands behind an answer from
//                      each family, with both axes, from the release's own
//                      generated `capability_inventory_v1.json`.
//   SESSION FUNCTION   function — established only by tools executed in this
//                      shell session. Nothing else may colour the indicator.
//
// The two laws and the engine's governing non-claim are pinned outside the
// scroll area, because they are the lines that must never be scrolled away.
Panel {
  id: root
  moduleName: "khephri.jackal"
  ipcTarget: "khephri.jackal"
  manageIpc: false

  property string focusSection: "header"
  property int registerIndex: 0
  property bool cursorActive: false

  // Dropdown-only professional machine-HUD palette: matte graphite, cold
  // instrument white, and one disciplined crimson channel. The dropdown uses
  // no green and no decorative colour that can be mistaken for evidence state.
  // The bar glyph itself keeps the operator's theme colours, so this does not
  // change the widget's established status semantics in the menu bar.
  readonly property color panelVoid: "#050506"
  readonly property color panelSurface: "#111214"
  readonly property color telemetry: "#c8cdd3"
  readonly property color signal: "#f1f3f5"
  readonly property color reentry: "#d51f2d"
  readonly property color frost: "#e8eaed"

  readonly property color foreground: frost
  readonly property color urgent: reentry
  readonly property color dim: Qt.alpha(frost, 0.68)
  readonly property color faint: Qt.alpha(frost, 0.44)
  readonly property color barUrgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string evidenceState: jackal.evidenceState
  readonly property bool affirmative: Model.isAffirmative(evidenceState)
  readonly property bool alarming: Model.isAlarming(evidenceState)

  // In-panel colour: established → signal, refusal or downgrade →
  // urgent, not established → dim. There is no colour that means "probably
  // fine".
  readonly property color stateColor: alarming ? urgent : (affirmative ? signal : dim)
  readonly property color barIconColor: alarming
    ? barUrgent
    : (affirmative ? barForeground : Qt.darker(barForeground, 1.55))

  readonly property string ageText: Model.ageText(jackal.receivedAtMs, jackal.nowMs)
  readonly property string metaText: Model.stateLabel(evidenceState)
    + (jackal.hostText !== "" ? " · " + jackal.hostText : "")
    + " · probed " + ageText

  readonly property int registerCount: jackal.familyRows.length

  function ensureCursor() {
    if (registerCount === 0) {
      focusSection = "header"
      registerIndex = 0
      return
    }
    if (focusSection !== "register" && focusSection !== "header") focusSection = "register"
    if (registerIndex >= registerCount) registerIndex = registerCount - 1
    if (registerIndex < 0) registerIndex = 0
  }

  function moveCursor(dx, dy) {
    cursorActive = true
    ensureCursor()
    if (dy === 0) return
    if (focusSection === "header") {
      if (dy > 0 && registerCount > 0) {
        focusSection = "register"
        registerIndex = 0
        scrollCursorIntoView()
      }
      return
    }
    if (focusSection === "register") {
      if (dy < 0 && registerIndex === 0) {
        setHeaderCursor()
        return
      }
      registerIndex = Math.max(0, Math.min(registerCount - 1, registerIndex + dy))
      scrollCursorIntoView()
    }
  }

  function setHeaderCursor() {
    cursorActive = true
    focusSection = "header"
    if (panelFlick) panelFlick.contentY = 0
  }

  function setRegisterCursor(index) {
    cursorActive = true
    focusSection = "register"
    registerIndex = index
    scrollCursorIntoView()
  }

  function selectedRegisterRow() {
    if (registerCount === 0) return null
    return jackal.familyRows[Math.max(0, Math.min(registerIndex, registerCount - 1))]
  }

  function activateCursor() {
    ensureCursor()
    if (focusSection === "header") {
      jackal.refresh()
      return
    }
    var row = selectedRegisterRow()
    // What you take away from a family is which tools are in it — so you know
    // exactly which ones you are allowed to lean on, and how far.
    if (row) jackal.copyText(row.tools.join(" "), row.family + " tools")
  }

  function scrollItemIntoView(item) {
    if (!panelFlick || !item) return
    Qt.callLater(function() {
      if (!item) return
      var margin = Style.space(6)
      var point = item.mapToItem(panelFlick.contentItem, 0, 0)
      var top = point.y
      var bottom = top + item.height
      var viewTop = panelFlick.contentY
      var viewBottom = viewTop + panelFlick.height
      var maxY = Math.max(0, panelFlick.contentHeight - panelFlick.height)
      if (top < viewTop + margin) panelFlick.contentY = Math.max(0, top - margin)
      else if (bottom > viewBottom - margin) panelFlick.contentY = Math.min(maxY, bottom + margin - panelFlick.height)
    })
  }

  function scrollCursorIntoView() {
    if (focusSection === "register" && registerColumn && registerIndex >= 0 && registerIndex < registerColumn.children.length)
      scrollItemIntoView(registerColumn.children[registerIndex])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    if (panelFlick) panelFlick.contentY = 0
    jackal.refreshIfStale()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }
  onRegisterIndexChanged: scrollCursorIntoView()

  Service {
    id: jackal
    settings: root.settings
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function probe(): string { jackal.refresh(); return "probing" }
    function verify(): string { jackal.runVerify(); return "verifying" }
    // The classification, not a bare "ok": a caller scripting against this sees
    // the same word the bar is showing, drawn from JACKAL's own vocabulary.
    function status(): string { return Model.stateLabel(root.evidenceState) }
    function nonclaim(): string { return jackal.nonClaim }
    // Verify whatever the clipboard holds against the operator's standing
    // authorization. Returns the verdict word, not a bare "ok".
    function verifyClipboard(): string {
      jackal.verifyArtifact()
      return "verifying"
    }
    function verdict(): string {
      return jackal.verifyResult ? String(jackal.verifyResult.status) : "not-run"
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.stateGlyph(root.evidenceState)
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    foreground: root.barIconColor
    tooltipText: Model.tooltip(root.evidenceState, jackal.report, jackal.receivedAtMs, jackal.nowMs)

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) jackal.refresh()
      else if (buttonCode === Qt.MiddleButton) jackal.runVerify()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    borderSpec: Border.flat(root.reentry, Math.max(1, Style.space(1)))
    contentWidth: panel.fittedContentWidth(Style.space(520))
    contentHeight: panel.fittedContentHeight(column.implicitHeight + footer.implicitHeight + Style.space(12), Style.space(1200))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      Rectangle {
        anchors.fill: parent
        z: -6
        gradient: Gradient {
          GradientStop { position: 0.0; color: "#111214" }
          GradientStop { position: 0.56; color: root.panelVoid }
          GradientStop { position: 1.0; color: "#020203" }
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.space(2)
        z: -3
        gradient: Gradient {
          GradientStop { position: 0.0; color: root.reentry }
          GradientStop { position: 0.72; color: Qt.darker(root.reentry, 1.7) }
          GradientStop { position: 1.0; color: Qt.alpha(root.telemetry, 0.34) }
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Style.space(80)
        z: -3
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.alpha(root.reentry, 0.17) }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Style.space(2)
        z: -2
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: root.reentry }
          GradientStop { position: 0.68; color: root.reentry }
          GradientStop { position: 1.0; color: Qt.alpha(root.telemetry, 0.28) }
        }
      }
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        var key = String(t).toLowerCase()
        if (key === "r") jackal.refresh()
        else if (key === "v") jackal.runVerify()
        else if (key === "c") jackal.copyText(jackal.packageSha, "package digest")
        else if (key === "n") jackal.copyText(jackal.nonClaim, "non-claim")
        else if (key === "p") jackal.verifyArtifact()
      }

      Flickable {
        id: panelFlick
        anchors.left: parent.left
        anchors.leftMargin: Style.space(9)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(3)
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Style.space(10)
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        // Kinetic scrolling otherwise places glyphs on fractional device
        // pixels, producing visible shimmer on this high-contrast HUD palette.
        pixelAligned: true
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Rectangle {
          id: readingPlaneBackground
          width: panelFlick.width
          height: column.implicitHeight
          color: root.panelVoid
          z: -1
        }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(11)
          // Render the complete reading surface as one opaque device-pixel
          // layer. Text no longer re-composites independently against moving
          // translucent decoration while the viewport scrolls.
          layer.enabled: true
          layer.smooth: false
          layer.mipmap: false

          Item {
            id: header
            width: parent.width
            implicitHeight: hero.implicitHeight + Style.space(18)
            readonly property bool ringVisible: root.cursorActive && root.focusSection === "header"
            function focusHero() { root.setHeaderCursor() }

            Rectangle {
              anchors.fill: parent
              radius: Style.cornerRadius
              color: root.panelSurface
              border.color: header.ringVisible ? root.signal : Qt.alpha(root.reentry, 0.46)
              border.width: header.ringVisible ? Math.max(1, Style.space(1)) : 1
            }

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              width: Style.space(44)
              height: Style.space(2)
              color: root.reentry
              opacity: 0.88
            }

            Rectangle {
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              width: Style.space(32)
              height: Style.space(2)
              color: root.telemetry
              opacity: 0.72
            }

            PanelHero {
              id: hero
              anchors.fill: parent
              anchors.margins: Style.space(9)
              title: "JACKAL + THOTH"
              detail: jackal.epoch
              meta: root.metaText
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconOpacity: root.affirmative ? 1.0 : 0.65
              iconComponent: Component {
                Text {
                  text: Model.stateGlyph(root.evidenceState)
                  color: root.stateColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                }
              }

              trailingControl: Component {
                PanelActionButton {
                  iconText: Model.GLYPH.refresh
                  tooltipText: "Run a function probe now"
                  foreground: hero.foreground
                  fontFamily: hero.fontFamily
                  hasCursor: header.ringVisible
                  enabled: !jackal.busy
                  onHovered: function(on) { if (on) header.focusHero() }
                  onClicked: jackal.refresh()
                }
              }
            }
          }

          Text {
            width: parent.width
            text: jackal.actionStatus !== "" ? jackal.actionStatus
                  : (jackal.lastError !== "" ? jackal.lastError
                     : Model.stateBlurb(root.evidenceState, jackal.report))
            color: jackal.lastError !== "" && jackal.actionStatus === "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          LatestAnswerCard {
            width: parent.width
            row: jackal.results.length > 0 ? jackal.results[0] : null
          }

          PanelSeparator { foreground: root.telemetry }

          GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: Style.space(6)
            rowSpacing: Style.space(6)

            TelemetryStat {
              Layout.fillWidth: true
              label: "DOCTOR VERDICT"
              value: jackal.verdict !== "" ? jackal.verdict : "—"
              tone: root.stateColor
            }
            TelemetryStat {
              Layout.fillWidth: true
              label: "IDENTITY MATCH"
              value: jackal.report ? (jackal.identityMatch ? "yes" : "no") : "—"
              tone: jackal.report && jackal.identityMatch ? root.signal : root.dim
            }
            TelemetryStat {
              Layout.fillWidth: true
              label: "RUNTIME VERIFY"
              value: jackal.verifyText !== "" ? jackal.verifyText : "not run this session"
              tone: jackal.verifyText !== "" ? root.telemetry : root.dim
            }
            TelemetryStat {
              Layout.fillWidth: true
              label: "Z3 / Anubis compiler"
              value: jackal.report
                     ? (jackal.z3Present ? "present" : "absent") + " / " + (jackal.anubisPresent ? "present" : "absent")
                     : "—"
              tone: jackal.report && jackal.z3Present && jackal.anubisPresent ? root.signal : root.dim
            }
          }

          // ---- Unified JACKAL + THOTH architecture and graph preview -------
          Column {
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader {
              text: "ONE ENGINE — EXPANDED CODEX SURFACE"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              text: "THOTH lives inside JACKAL as its measurement and provenance subsystem. "
                    + "The current Codex package joins the sealed runtime, THOTH, and the "
                    + "CAS / graph / nonlinear-certificate layer plus linked STEM workflows "
                    + "behind one identity-gated server."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            GridLayout {
              width: parent.width
              columns: 2
              columnSpacing: Style.space(6)
              rowSpacing: Style.space(6)

              TelemetryStat { Layout.fillWidth: true; label: "UNIFIED SURFACE"; value: "58 tools"; tone: root.telemetry }
              TelemetryStat { Layout.fillWidth: true; label: "SEALED RUNTIME"; value: "41 evidence tools"; tone: root.signal }
              TelemetryStat { Layout.fillWidth: true; label: "INTEGRATED THOTH"; value: "7 measurement / provenance tools"; tone: root.signal }
              TelemetryStat { Layout.fillWidth: true; label: "CAS + GRAPH + CERT"; value: "3 advanced tools"; tone: root.telemetry }
              TelemetryStat { Layout.columnSpan: 2; Layout.fillWidth: true; label: "STEM WORKFLOWS"; value: "7 linked engineering tools"; tone: root.reentry }
            }

            Rectangle {
              width: parent.width
              height: graphDeck.implicitHeight + Style.space(20)
              radius: Style.cornerRadius
              color: root.panelSurface
              border.color: Qt.alpha(root.reentry, 0.44)
              border.width: 1
              clip: true

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Style.space(2)
                gradient: Gradient {
                  orientation: Gradient.Horizontal
                  GradientStop { position: 0.0; color: root.reentry }
                  GradientStop { position: 0.34; color: root.reentry }
                  GradientStop { position: 0.62; color: root.telemetry }
                  GradientStop { position: 1.0; color: root.reentry }
                }
              }

              Column {
                id: graphDeck
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(7)

                RowLayout {
                  width: parent.width
                  spacing: Style.space(8)

                  Text {
                    text: "GRAPH DECK"
                    color: root.telemetry
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 1.4
                  }

                  Item { Layout.fillWidth: true }

                  StatusPill { label: "HELLGATE / V(x)"; tone: root.signal }
                }

                Image {
                  id: graphPreview
                  width: parent.width
                  height: width * 3 / 5
                  source: Qt.resolvedUrl("assets/jackal-thoth-hellgate-graph.png")
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  smooth: true
                  mipmap: true
                }
              }
            }

            Text {
              width: parent.width
              text: "HELLGATE potential · status=estimated visualization. Exact rational x "
                    + "coordinates; estimated f64 y samples; pixels are not proof."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
              horizontalAlignment: Text.AlignHCenter
            }
          }

          PanelSeparator { foreground: root.foreground }

          // ---- Verification: the front door, exercised rather than described
          //
          // First, deliberately. In the `core` profile an agent must verify
          // before it can speak, and a widget that rendered that rule while
          // never keeping it would be describing a discipline it does not hold.
          Column {
            width: parent.width
            spacing: Style.space(5)

            PanelSectionHeader {
              text: "VERIFY — CLIPBOARD ARTIFACT"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              text: "The artifact comes from the clipboard; the authorization comes from "
                    + "your expectations file. Expectations taken from the artifact would "
                    + "make every check pass and mean nothing."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              visible: jackal.verifyResult === null
              width: parent.width
              text: jackal.verifyBusy ? "Verifying…"
                    : "Nothing verified in this session.  press p"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            VerdictBlock {
              width: parent.width
              visible: jackal.verifyResult !== null
              result: jackal.verifyResult
            }
          }

          PanelSeparator { foreground: root.foreground }

          // ---- Latest results: what this machine actually computed ---------
          //
          // Work done through the MCP surface, not by this widget. Every field
          // is JACKAL's own: the status class it returned, and either its own
          // output line or, for a refusal, the reason it named. Nothing here
          // re-ranks or softens a class.
          Column {
            width: parent.width
            spacing: Style.space(5)

            PanelSectionHeader {
              text: jackal.results.length > 0
                    ? "LATEST RESULTS — " + Model.pluralAnswers(jackal.results.length)
                    : "LATEST RESULTS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              text: "Recent answers recorded by the configured JACKAL ledger, newest first. The status word is "
                    + "the class JACKAL returned; a refusal is shown with the reason it named. "
                    + "This is a local record of calls that already happened — not a "
                    + "re-verification. It establishes nothing on its own."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              visible: jackal.results.length === 0
              width: parent.width
              text: "Nothing computed yet."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Column {
              id: resultColumn
              visible: jackal.results.length > 0
              width: parent.width
              spacing: Style.space(3)

              Repeater {
                model: jackal.results
                ResultRow {
                  required property var modelData
                  width: resultColumn.width
                  row: modelData
                }
              }
            }
          }
          PanelSeparator { foreground: root.foreground }

          // ---- Function: what actually ran here, this session --------------
          Column {
            width: parent.width
            spacing: Style.space(5)

            PanelSectionHeader {
              text: jackal.probeTotal > 0
                    ? "SESSION FUNCTION — " + jackal.probePassed + "/" + jackal.probeTotal
                      + " AT DECLARED CLASS"
                    : "SESSION FUNCTION"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              text: "One real tool per class, executed here. A declared class is never evidence "
                    + "that the class executed."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              visible: jackal.probeTotal === 0
              width: parent.width
              text: "Nothing executed yet."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Column {
              id: probeColumn
              visible: jackal.probeTotal > 0
              width: parent.width
              spacing: Style.space(1)

              Repeater {
                model: jackal.probeRows
                ProbeRow {
                  required property var modelData
                  width: probeColumn.width
                  row: modelData
                }
              }
            }
          }
          PanelSeparator { foreground: root.foreground }

          DigestRow {
            width: parent.width
            visible: jackal.packageSha !== ""
            caption: "Package digest"
            digest: jackal.packageSha
            description: "package digest"
          }

          DigestRow {
            width: parent.width
            visible: jackal.catalogSha !== ""
            caption: "Tool catalog digest"
            digest: jackal.catalogSha
            description: "catalog digest"
          }

          PanelSeparator { foreground: root.foreground }

          // ---- The operator's lever: which tools a profile exposes ---------
          Column {
            width: parent.width
            spacing: Style.space(5)

            PanelSectionHeader {
              text: jackal.declaredToolCount > 0
                    ? "AGENT SURFACE — " + jackal.declaredToolCount + " TOOLS DECLARED"
                    : "AGENT SURFACE"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              text: "Widening a profile is an explicit operator act, never a fallback."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              visible: jackal.profileRows.length === 0
              width: parent.width
              text: jackal.epoch === "" ? "No runtime epoch established." : "Reading the declared surface…"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Column {
              width: parent.width
              spacing: Style.space(2)

              Repeater {
                model: jackal.profileRows
                ProfileRow {
                  required property var modelData
                  width: parent ? parent.width : 0
                  row: modelData
                }
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          // ---- Capability: what actually stands behind each answer ---------
          Column {
            width: parent.width
            spacing: Style.space(5)

            PanelSectionHeader {
              text: root.registerCount > 0
                    ? "EVIDENCE REGISTER — " + root.registerCount + " FAMILIES"
                    : "EVIDENCE REGISTER"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              text: "Assurance is how well a fact is established; consequence is what may be "
                    + "decided on it. Neither raises the other. " + Model.GLYPH.capped
                    + " marks a ceiling held below the assurance — proved more than it "
                    + "may decide. That is the bound holding, not a fault."
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              visible: root.registerCount === 0
              width: parent.width
              text: jackal.epoch === "" ? "No runtime epoch established." : "Reading the capability inventory…"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Column {
              id: registerColumn
              visible: root.registerCount > 0
              width: parent.width
              spacing: Style.space(2)

              Repeater {
                model: jackal.familyRows
                RegisterRow {
                  required property var modelData
                  required property int index
                  width: registerColumn.width
                  row: modelData
                  rowIndex: index
                }
              }
            }
          }

        }
      }

      // Pinned: the two laws and the governing non-claim never scroll away.
      Column {
        id: footer
        anchors.left: parent.left
        anchors.leftMargin: Style.space(9)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(3)
        anchors.bottom: parent.bottom
        spacing: Style.space(3)

        PanelSeparator { foreground: root.foreground }

        Item { width: 1; height: Style.space(4) }

        // Observed from these exact inventory bytes, not asserted as a standing
        // law — the difference matters on a surface whose whole point is that
        // claims are only as strong as what backs them.
        //
        // Three states, never two. Silence means the inventory has not been
        // read, so nothing is established either way. A surface where the law
        // has STOPPED holding says which tool broke it, in the alarm colour: a
        // law that quietly disappears when it fails is worse than no law, and
        // is exactly the silent downgrade this project refuses.
        Text {
          visible: jackal.inventory !== null
          width: parent.width
          text: jackal.everyToolDeclaresRefused
                ? "refused is a declared outcome of all " + jackal.declaredToolCount
                  + " tools. A ceiling is an upper bound, never a grant."
                : jackal.toolsWithoutRefused.length + " of " + jackal.declaredToolCount
                  + " tools do NOT declare refused: "
                  + jackal.toolsWithoutRefused.join(", ")
          color: jackal.everyToolDeclaresRefused ? root.dim : root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Item { visible: jackal.inventory !== null; width: 1; height: Style.space(3) }

        Text {
          visible: jackal.nonClaim !== ""
          width: parent.width
          text: "NON-CLAIM"
          color: root.telemetry
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
        }

        Text {
          visible: jackal.nonClaim !== ""
          width: parent.width
          text: jackal.nonClaim
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Item { width: 1; height: Style.space(2) }

        Text {
          width: parent.width
          text: "p verify clipboard · r probe · v runtime · c digest · n non-claim"
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
      }
    }
  }

  // A compact command strip keeps the newest recorded answer above the fold.
  // It is intentionally labelled LOCAL RECALL: the ledger is a convenience
  // file, not evidence, and this card never upgrades or reclassifies a result.
  component LatestAnswerCard: Rectangle {
    id: latestCard
    property var row: null

    readonly property color tone: row && row.refused ? root.dim : root.telemetry

    implicitHeight: latestContent.implicitHeight + Style.space(22)
    radius: Style.cornerRadius
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
      anchors.left: parent.left
      anchors.leftMargin: Style.space(13)
      anchors.right: parent.right
      anchors.rightMargin: Style.space(11)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(4)

      RowLayout {
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: "LATEST ANSWER  /  LOCAL RECALL"
          color: root.telemetry
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.4
        }

        Item { Layout.fillWidth: true }

        StatusPill {
          visible: latestCard.row !== null
          label: latestCard.row ? latestCard.row.status : ""
          tone: latestCard.tone
        }
      }

      Text {
        width: parent.width
        text: latestCard.row ? latestCard.row.tool : "No recorded answer yet"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        visible: latestCard.row ? latestCard.row.request !== "" : false
        width: parent.width
        text: latestCard.row ? latestCard.row.request : ""
        color: root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: latestCard.row
              ? (latestCard.row.detail !== "" ? latestCard.row.detail : "No result detail recorded.")
              : "The newest ledger entry will appear here without reopening the dropdown."
        color: latestCard.row && latestCard.row.refused ? root.dim : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      RowLayout {
        visible: latestCard.row !== null
        width: parent.width
        spacing: Style.space(8)

        Text {
          text: latestCard.row ? Model.ageText(latestCard.row.atMs, jackal.nowMs) : ""
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "recall only · not re-verified"
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  component StatusPill: Rectangle {
    id: statusPill
    property string label: ""
    property color tone: root.telemetry

    implicitWidth: pillText.implicitWidth + Style.space(12)
    implicitHeight: pillText.implicitHeight + Style.space(5)
    radius: implicitHeight / 2
    color: Qt.alpha(tone, 0.11)
    border.color: Qt.alpha(tone, 0.62)
    border.width: 1

    Text {
      id: pillText
      anchors.centerIn: parent
      text: statusPill.label
      color: statusPill.tone
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }

  component TelemetryStat: Rectangle {
    id: stat
    property string label: ""
    property string value: ""
    property color tone: root.telemetry

    implicitWidth: Style.space(160)
    implicitHeight: statContent.implicitHeight + Style.space(14)
    radius: Style.cornerRadius
    color: root.panelSurface
    border.color: Qt.alpha(stat.tone, 0.28)
    border.width: 1

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      width: Style.space(28)
      height: 1
      color: stat.tone
      opacity: 0.78
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      width: 1
      height: Style.space(8)
      color: stat.tone
      opacity: 0.78
    }

    Column {
      id: statContent
      anchors.left: parent.left
      anchors.leftMargin: Style.space(8)
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: stat.label
        color: stat.tone
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.0
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: stat.value
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }
    }
  }

  // One verification verdict, verbatim.
  //
  // `raised_by` is shown because it is load-bearing: a refusal from this widget
  // means the artifact never reached a front door, and a refusal from JACKAL
  // means the front door looked and said no. Rendering those the same way would
  // let a routing failure read as a verification result.
  //
  // The authorization is shown because an authorization the operator cannot see
  // is one they cannot audit — and because "it refused" is only answerable next
  // to "here is what you authorized".
  component VerdictBlock: Column {
    id: verdict
    property var result: null

    readonly property bool affirmative: Model.verifyIsAffirmative(result)
    readonly property bool alarming: Model.verifyIsAlarming(result)
    readonly property bool refusal: Model.verifyIsRefusal(result)
    readonly property color tone: alarming ? root.urgent
                                           : (affirmative ? root.foreground : root.dim)

    spacing: Style.space(3)

    RowLayout {
      width: parent.width
      spacing: Style.space(8)

      Text {
        text: verdict.affirmative ? Model.GLYPH.pass : Model.GLYPH.fail
        color: verdict.tone
        opacity: verdict.affirmative ? 0.85 : 1.0
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        text: Model.verifyStatusLabel(verdict.result ? verdict.result.status : "")
        color: verdict.tone
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        font.letterSpacing: 1.0
      }

      Item { Layout.fillWidth: true }

      Text {
        text: Model.verifySubject(verdict.result)
        color: root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideLeft
        Layout.maximumWidth: parent.width * 0.55
      }
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: verdict.result && verdict.result.reason ? verdict.result.reason : ""
      color: verdict.tone
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: verdict.result && verdict.result.detail ? verdict.result.detail : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      visible: verdict.refusal
      text: Model.verifyRaisedByText(verdict.result)
      color: root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Item { width: 1; height: Style.space(2) }

    Text {
      width: parent.width
      text: "AUTHORIZED BY YOU"
      color: Qt.darker(root.foreground, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.0
      visible: Model.authorizedRows(verdict.result).length > 0
    }

    Column {
      id: authorized
      width: parent.width
      spacing: Style.space(1)

      Repeater {
        model: Model.authorizedRows(verdict.result)
        Row {
          required property var modelData
          width: authorized.width
          spacing: Style.space(8)

          Text {
            text: modelData.name
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
          Item {
            width: Math.max(0, authorized.width - parent.children[0].implicitWidth
                               - parent.children[2].implicitWidth - Style.space(16))
            height: 1
          }
          Text {
            text: modelData.value
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: verdict.result && verdict.result.reason === "widget-expectations-absent"
      text: "Write an authorization file at " + jackal.expectationsPath
            + " — see the plugin README for the template."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Item { width: 1; height: Style.space(2); visible: reportColumn.children.length > 0 }

    Column {
      id: reportColumn
      width: parent.width
      spacing: 0

      Repeater {
        model: verdict.result && verdict.result.report ? verdict.result.report : []
        Text {
          required property var modelData
          width: reportColumn.width
          text: modelData
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WrapAnywhere
        }
      }
    }
  }

  component DigestRow: CursorSurface {
    id: digestRow
    property string caption: ""
    property string digest: ""
    property string description: ""

    hasCursor: false
    foreground: root.foreground
    implicitHeight: digestContent.implicitHeight + Style.spacing.sm

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: jackal.copyText(digestRow.digest, digestRow.description)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      ColumnLayout {
        id: digestContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          Layout.fillWidth: true
          text: digestRow.caption
          color: root.foreground
          opacity: 0.6
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          Layout.fillWidth: true
          text: Model.shortHash(digestRow.digest)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }

      PanelActionButton {
        iconText: Model.GLYPH.copy
        tooltipText: "Copy the full digest"
        foreground: root.foreground
        fontFamily: root.fontFamily
        Layout.alignment: Qt.AlignVCenter
        onClicked: jackal.copyText(digestRow.digest, digestRow.description)
      }
    }
  }

  // One profile: its name, how many tools it exposes, and why it exists.
  component ProfileRow: Item {
    id: profileRow
    property var row: null

    implicitHeight: profileContent.implicitHeight + Style.space(4)

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (profileRow.row) jackal.copyText(profileRow.row.name, profileRow.row.name + " profile")
    }

    ColumnLayout {
      id: profileContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(1)

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Text {
          text: profileRow.row ? profileRow.row.name : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }

        Item { Layout.fillWidth: true }

        Text {
          text: profileRow.row ? Model.pluralTools(profileRow.row.count) : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: profileRow.row ? profileRow.row.meaning : ""
        color: root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  // One family of the declared surface: how many tools sit in it, the two axes
  // it declares, and — in one sentence — what actually stands behind an answer
  // from it. The axes are printed side by side and never combined; a ceiling
  // strictly below the assurance is marked, because that gap is the
  // anti-laundering boundary and the load-bearing half.
  //
  // The mark is deliberately NOT in the failure vocabulary. It is a fact about
  // a family that is working exactly as designed — it proves more than it is
  // allowed to decide on — so it is undimmed rather than urgent, and carries
  // its own glyph rather than the alert triangle a failed probe uses.
  component RegisterRow: CursorSurface {
    id: registerRow
    property var row: null
    property int rowIndex: 0

    hasCursor: root.cursorActive && root.focusSection === "register" && root.registerIndex === rowIndex
    foreground: root.foreground
    implicitHeight: registerContent.implicitHeight + Style.spacing.sm

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.setRegisterCursor(registerRow.rowIndex)
      onClicked: root.activateCursor()
    }

    ColumnLayout {
      id: registerContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(1)

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Text {
          text: registerRow.row ? registerRow.row.family : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Item { Layout.fillWidth: true }

        Text {
          text: registerRow.row ? Model.pluralTools(registerRow.row.toolCount) : ""
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      // The two axes, side by side, never merged into one word.
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(6)

        Text {
          text: "assurance"
          color: root.foreground
          opacity: 0.55
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          Layout.fillWidth: true
          text: registerRow.row ? registerRow.row.assurance : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Text {
          text: "consequence"
          color: root.foreground
          opacity: 0.55
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          text: registerRow.row ? registerRow.row.consequence : ""
          // Undimmed because a cap is an established, load-bearing fact worth
          // reading — NOT urgent, which this panel reserves for a refusal or a
          // downgrade. A ceiling holding is the design working.
          color: registerRow.row && registerRow.row.capped ? root.foreground : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: registerRow.row ? registerRow.row.capped === true : false
          text: Model.GLYPH.capped
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      // Profile membership is the AGENT SURFACE section's job; repeating it on
      // every family would be noise. What belongs here is the one thing this
      // row exists to say: what stands behind an answer from it.
      Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: registerRow.row ? registerRow.row.backing : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  // One executed probe: the class, the tool that ran, and what status it came
  // back with. A status that differs from the declared one is printed with the
  // declaration beside it, in the alarm colour, so a downgrade cannot read as a
  // pass.
  // One answer JACKAL actually returned: what was asked, what class came back,
  // and the engine's own line.
  //
  // Nothing here is urgent-coloured. A refusal is JACKAL declining to stand
  // behind a number — the kernel working, not failing — so it is dimmed (it
  // established nothing) rather than alarmed. Colour here means established or
  // not established, exactly as the rest of the panel uses it.
  component ResultRow: Rectangle {
    id: resultRow
    property var row: null

    readonly property color tone: row && row.refused ? root.dim : root.telemetry

    implicitHeight: resultContent.implicitHeight + Style.space(14)
    radius: Style.cornerRadius
    color: root.panelSurface
    border.color: Qt.alpha(resultRow.tone, 0.24)
    border.width: 1

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: Style.space(2)
      color: resultRow.tone
      opacity: 0.72
    }

    Column {
      id: resultContent
      anchors.left: parent.left
      anchors.leftMargin: Style.space(10)
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      RowLayout {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: resultRow.row ? resultRow.row.tool : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Item { Layout.fillWidth: true }

        Text {
          // The class verbatim, then when. `lane` is omitted: the tool name
          // already identifies it, and repeating it reads as extra evidence.
          text: resultRow.row
                ? resultRow.row.status + "  ·  " + Model.ageText(resultRow.row.atMs, jackal.nowMs)
                : ""
          color: resultRow.tone
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      Text {
        visible: resultRow.row ? resultRow.row.request !== "" : false
        width: parent.width
        text: resultRow.row ? resultRow.row.request : ""
        color: root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      Text {
        visible: resultRow.row ? resultRow.row.detail !== "" : false
        width: parent.width
        text: resultRow.row ? resultRow.row.detail : ""
        color: resultRow.row && resultRow.row.refused ? root.dim : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      // Only a formal receipt has one. It is the single thing on this row that
      // can be taken to a front door and checked, so it is shown rather than
      // summarised away — and its absence on every other row is itself honest.
      // A retained receipt is the ONLY thing on this row that can be turned back
      // into evidence. Clicking sends it to the same front door the clipboard uses,
      // against the same operator-owned expectations — which will refuse unless
      // they authorize this exact request. That refusal is the correct answer.
      Item {
        visible: resultRow.row ? resultRow.row.digest !== "" : false
        width: parent.width
        implicitHeight: receiptLine.implicitHeight

        Text {
          id: receiptLine
          width: parent.width
          text: {
            if (!resultRow.row) return ""
            var base = "receipt " + Model.shortHash(resultRow.row.digest)
            return resultRow.row.retained
                   ? base + "  ·  retained — click to re-verify"
                   : base + "  ·  not retained"
          }
          color: receiptArea.containsMouse ? root.foreground : root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        MouseArea {
          id: receiptArea
          anchors.fill: parent
          hoverEnabled: true
          enabled: resultRow.row ? resultRow.row.retained === true : false
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: if (resultRow.row) jackal.verifyReceiptDigest(resultRow.row.digest)
        }
      }
    }
  }

  component ProbeRow: Item {
    id: probeRow
    property var row: null
    readonly property bool passed: row ? row.pass === true : false
    readonly property bool downgraded: row ? (row.executed !== row.expected) : false

    implicitHeight: probeLine.implicitHeight + Style.space(4)

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (probeRow.row) jackal.copyText(probeRow.row.tool, probeRow.row.tool)
    }

    RowLayout {
      id: probeLine
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        text: probeRow.passed ? Model.GLYPH.pass : Model.GLYPH.fail
        color: probeRow.passed ? root.foreground : root.urgent
        opacity: probeRow.passed ? 0.85 : 1.0
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: probeRow.row ? probeRow.row.name : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        Layout.preferredWidth: Style.space(96)
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        text: probeRow.row
              ? probeRow.row.tool + (probeRow.downgraded ? "  ⚠ " + probeRow.row.executed + " ≠ " + probeRow.row.expected : "")
              : ""
        color: probeRow.downgraded ? root.urgent : root.faint
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideLeft
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""

    width: parent.width
    spacing: Style.space(8)

    InfoLabel { text: label }
    Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
    InfoValue { text: value }
  }

  component InfoLabel: Text {
    color: root.foreground
    opacity: 0.6
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  component InfoValue: Text {
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }
}
