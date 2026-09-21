// JACKAL COCKPIT — full-screen mission control for the evidence kernel.
//
// Overlay kind: summoned from the bar widget, SUPER+SHIFT+J, or
// `omarchy-shell shell summon khephri.jackal '{}'`; dismissed with Esc / ✕.
//
// JOP-UI-001: returned assurance vocabulary is rendered without promotion.
//
// JACKAL is a mathematical evidence kernel: every answer declares what kind of
// answer it is, refusal is a first-class answer, and two independent things are
// always stated — how well a fact is established (ASSURANCE) and what may be
// decided on it (CONSEQUENCE). A ceiling is an upper bound, never a grant.
//
// THOTH is JACKAL's integrated measurement/provenance subsystem, not a second
// engine. THOTH lives inside JACKAL — one engine, one identity.
//
// The cockpit keeps these accounts strictly apart and never merges them into a
// score:
//
//   OVERVIEW   every account at once, none of them summarised into another
//   LEDGER     local recall of returned answers — a file this tooling wrote
//   GRAPH      an explicitly NON-EVIDENTIARY sweep of the sealed evaluator;
//              graph pixels are visualization, never evidence
//   PROBES     function — established only by tools executed in this session
//   VERIFY     the one section that ACTS: a clipboard receipt or bundle goes
//              to a real front door, against an authorization the operator
//              owns — never from the artifact under review
//   REGISTER   capability — what stands behind each family, both axes
//   THOTH      the sealed runtime identity and measurement provenance
//
// Every colour, size and spacing comes from the operator's theme through the
// shell's Color and Style singletons, the way Omarchy's own overlays draw.
// State colours have no middle: established → text colour, refusal or
// downgrade → urgent, not established → dimmed. Accent is chrome and the
// activity instrument only; it is never a state.

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

  readonly property string pluginId:
    root.manifest && typeof root.manifest.id === "string"
      && root.manifest.id !== "" ? root.manifest.id : "khephri.jackal"

  // ------------------------------------------------------------------ theme
  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color accent: Color.accent
  readonly property color urgent: Color.urgent
  readonly property color scrimColor: Color.menu.scrim
  readonly property var cardBorder: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
  readonly property string fontFamily: Style.font.menuFamily
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property color faint: Util.alpha(foreground, 0.46)
  readonly property color hairline: Util.alpha(foreground, 0.10)
  readonly property color surface: Util.alpha(foreground, 0.035)

  // ----------------------------------------------------------------- state
  readonly property string evidenceState: jackal.evidenceState
  readonly property bool affirmative: Model.isAffirmative(root.evidenceState)
  readonly property bool alarming: Model.isAlarming(root.evidenceState)
  readonly property color stateColor: root.alarming
    ? root.urgent : (root.affirmative ? root.foreground : root.dim)
  readonly property string ageText: Model.ageText(jackal.receivedAtMs, jackal.nowMs)

  // ------------------------------------------------------------- aggregates
  // Counts of ledger rows over the operator's window. Recall, not evidence.
  readonly property int windowMs: jackal.activityWindowHours * 3600 * 1000
  readonly property var scoped: Model.rowsWithin(jackal.allResults, jackal.nowMs, root.windowMs)
  readonly property var summary: Model.ledgerSummary(jackal.allResults, jackal.nowMs, root.windowMs)
  readonly property var allSummary: Model.ledgerSummary(jackal.allResults, jackal.nowMs, 0)
  readonly property var activity: Model.activityBuckets(jackal.allResults, jackal.nowMs, root.windowMs, 48)
  readonly property var histogram: Model.statusHistogram(root.scoped)
  readonly property var leaderboard: Model.toolLeaderboard(jackal.allResults, 7)
  readonly property var newest: jackal.allResults.length > 0 ? jackal.allResults[0] : null
  readonly property bool newestFresh: jackal.ledgerAdvancedAtMs > 0
    && jackal.nowMs - jackal.ledgerAdvancedAtMs < 60000

  // --------------------------------------------------------------- sections
  property string section: "overview"
  readonly property var sections: [
    { key: "overview", label: "Overview", num: "1" },
    { key: "ledger",   label: "Ledger",   num: "2" },
    { key: "graph",    label: "Graph",    num: "3" },
    { key: "probes",   label: "Probes",   num: "4" },
    { key: "verify",   label: "Verify",   num: "5" },
    { key: "register", label: "Register", num: "6" },
    { key: "thoth",    label: "THOTH",    num: "7" }
  ]

  function sectionIndex(key) {
    for (var i = 0; i < root.sections.length; i++)
      if (root.sections[i].key === key) return i
    return 0
  }

  function selectSection(key) {
    if (root.sectionIndex(key) === 0 && key !== "overview") return
    root.section = key
    keyHost.forceActiveFocus()
  }

  function stepSection(delta) {
    var next = root.sectionIndex(root.section) + delta
    if (next < 0) next = root.sections.length - 1
    if (next >= root.sections.length) next = 0
    root.selectSection(root.sections[next].key)
  }

  // ------------------------------------------------------------ ledger view
  property string feedFilter: "all"
  property int feedCursor: -1
  property int feedExpanded: -1
  // The ledger deck's ListView, registered by the deck when it is built: an id
  // declared inside an inline component is not reachable from this scope.
  property var feedView: null
  readonly property var feed: Model.feedRows(jackal.allResults, root.feedFilter, 400)
  readonly property var feedFilters: [
    { key: "all", label: "All", count: root.allSummary.allTotal },
    { key: "answered", label: "Answered", count: root.allSummary.answered },
    { key: "refused", label: "Refused", count: root.allSummary.refused },
    { key: "formal", label: "Formal", count: root.allSummary.formal }
  ]

  function setFeedFilter(key) {
    root.feedFilter = key
    root.feedCursor = -1
    root.feedExpanded = -1
    pointerGate.reset()
    if (root.feedView) root.feedView.positionViewAtBeginning()
  }

  function moveFeed(delta) {
    if (root.feed.length === 0) return
    pointerGate.reset()
    var next = root.feedCursor < 0 ? (delta > 0 ? 0 : root.feed.length - 1) : root.feedCursor + delta
    root.feedCursor = Math.max(0, Math.min(root.feed.length - 1, next))
    if (root.feedView) root.feedView.positionViewAtIndex(root.feedCursor, ListView.Contain)
  }

  function toggleFeedRow(index) {
    root.feedCursor = index
    root.feedExpanded = root.feedExpanded === index ? -1 : index
    pointerGate.reset()
  }

  // Only deliberate pointer movement moves the ledger cursor: a row that
  // slides under a parked pointer during a keyboard scroll is ignored.
  function feedPointer(index, item, x, y) {
    if (!pointerGate.moved(item, { x: x, y: y })) return
    root.feedCursor = index
  }

  // ---------------------------------------------------------------- settings
  // Overlays are NOT handed `settings` by the shell the way bar widgets are.
  // The overlay walks the shell config itself; if this were skipped the
  // failure would be silent and every value would fall back to a default.

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

  // -------------------------------------------------------------- lifecycle
  // The shell's plugin Loader hands the summon payload to open(); isOpen()
  // then reads back `opened`. An optional { section } lands on that deck.
  function open(payloadJson) {
    var requested = ""
    if (payloadJson) {
      try {
        var parsed = JSON.parse(String(payloadJson))
        if (parsed && typeof parsed.section === "string") requested = parsed.section
      } catch (e) { /* an unreadable payload opens the overview */ }
    }
    if (requested !== "" && root.sectionIndex(requested) > 0 || requested === "overview")
      root.section = requested
    root.opened = true
    jackal.live = true
    jackal.refreshIfStale()
    jackal.readInventory()
    jackal.readResults()
    jackal.readNonClaim()
    // Name the provisioner and the tree state once per session; the pinned
    // tree check is a separate observation from the doctor's probes.
    if (!jackal.verifyReport) jackal.runVerify()
    root.ensureSweep()
    Qt.callLater(function() { keyHost.forceActiveFocus() })
  }

  // Mission control should not open on an empty instrument. This is a sweep of
  // the sealed evaluator like any other — still non-evidentiary, still labelled
  // as such on the canvas. On a cold open the doctor has not yet named the
  // runtime, so the sweep waits for it rather than refusing into an error the
  // operator did not cause.
  function ensureSweep() {
    if (!root.opened || jackal.runtimeDir === "") return
    if (jackal.graphPoints.length === 0 && !jackal.graphBusy)
      jackal.plotGraph(jackal.graphExpression, jackal.graphXMin, jackal.graphXMax)
  }

  Connections {
    target: jackal
    function onRuntimeDirChanged() { root.ensureSweep() }
  }

  function close() {
    root.opened = false
    jackal.live = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  PointerMoveGate {
    id: pointerGate
    referenceItem: card
  }

  Service {
    id: jackal
    settings: root.mergedSettings
    // The bar widget's service keeps the session account current on its own
    // clock; this copy probes on open and when asked, so two surfaces do not
    // run two doctors every interval.
    passive: true
  }

  // ------------------------------------------------------------------ shared

  // A card: the kit's alpha-on-foreground surface with a section title and a
  // note that states the standing of what it holds.
  component Card: BorderSurface {
    id: card
    property string title: ""
    property string note: ""
    property bool urgentEdge: false
    default property alias content: body.data

    color: root.surface
    borderSpec: Border.flat(card.urgentEdge ? Util.alpha(root.urgent, 0.35) : root.hairline, 1)
    radius: Style.cornerRadius
    padding: Style.space(14)
    implicitHeight: body.implicitHeight + card.padding * 2
      + (heading.visible ? heading.implicitHeight + Style.space(10) : 0)

    JkSectionTitle {
      id: heading
      visible: card.title !== ""
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: card.contentLeftInset
      anchors.rightMargin: card.contentRightInset
      anchors.topMargin: card.contentTopInset
      title: card.title
      note: card.note
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    ColumnLayout {
      id: body
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.top: heading.visible ? heading.bottom : parent.top
      anchors.leftMargin: card.contentLeftInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.topMargin: heading.visible ? Style.space(10) : card.contentTopInset
      spacing: Style.space(10)
    }
  }

  component Caption: Text {
    textFormat: Text.PlainText
    color: root.faint
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  component Body: Text {
    textFormat: Text.PlainText
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  component ColumnHead: Text {
    textFormat: Text.PlainText
    color: root.faint
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 1.0
    elide: Text.ElideRight
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
      anchors.fill: parent
      color: root.scrimColor
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: Math.min(Style.space(1340), cockpitWindow.width - Style.space(36))
      height: Math.min(Style.space(840), cockpitWindow.height - Style.space(36))
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.cardBorder
      radius: Style.cornerRadius
      padding: Style.space(20)
      opacity: root.opened ? 1 : 0
      scale: root.opened ? 1 : 0.985
      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      MouseArea {
        anchors.fill: parent
        onClicked: keyHost.forceActiveFocus()
      }

      FocusScope {
        id: keyHost
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        focus: true

        // Keys reach here only when no text field holds them, so typing an
        // expression into the graph deck never switches decks. Actions take
        // Shift so they cannot collide with the deck numbers.
        Keys.onPressed: function (event) {
          if (event.key === Qt.Key_Escape) { root.dismiss(); event.accepted = true; return }
          if (event.key === Qt.Key_Tab) { root.stepSection(1); event.accepted = true; return }
          if (event.key === Qt.Key_Backtab) { root.stepSection(-1); event.accepted = true; return }
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
          if (event.key >= Qt.Key_1 && event.key <= Qt.Key_7) {
            root.selectSection(root.sections[event.key - Qt.Key_1].key)
            event.accepted = true
            return
          }
          if (root.section === "ledger") {
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) { root.moveFeed(1); event.accepted = true; return }
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) { root.moveFeed(-1); event.accepted = true; return }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
              if (root.feedCursor >= 0) root.toggleFeedRow(root.feedCursor)
              event.accepted = true
              return
            }
          }
        }

        ColumnLayout {
          anchors.fill: parent
          spacing: Style.space(14)

          // ------------------------------------------------------- header
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)

            // Bounded, so a long tagline can never push the decks off the card.
            ColumnLayout {
              Layout.fillWidth: false
              Layout.preferredWidth: Style.space(270)
              Layout.maximumWidth: Style.space(270)
              spacing: Style.space(1)
              Row {
                spacing: Style.space(10)
                Text {
                  textFormat: Text.PlainText
                  text: "JACKAL"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  font.bold: true
                  font.letterSpacing: 4.5
                  anchors.verticalCenter: parent.verticalCenter
                }
                JkChip {
                  label: "+ THOTH"
                  tone: root.accent
                  fontFamily: root.fontFamily
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
              Caption {
                Layout.fillWidth: true
                text: "evidence kernel · mission control"
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
              }
            }

            Item { Layout.fillWidth: true }

            Row {
              spacing: Style.space(2)
              Repeater {
                model: root.sections
                delegate: Button {
                  required property var modelData
                  readonly property bool current: root.section === modelData.key
                  text: modelData.num + " " + modelData.label
                  selected: current
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  horizontalPadding: Style.space(10)
                  verticalPadding: Style.space(7)
                  onClicked: root.selectSection(modelData.key)
                }
              }
            }

            Item { Layout.fillWidth: true }

            Row {
              spacing: Style.space(8)

              JkChip {
                label: jackal.busy ? "PROBING…" : Model.stateLabel(root.evidenceState)
                tone: root.stateColor
                dot: true
                solid: root.affirmative
                fontFamily: root.fontFamily
                anchors.verticalCenter: parent.verticalCenter
              }
              JkChip {
                visible: jackal.epoch !== ""
                label: jackal.epoch
                tone: root.foreground
                fontFamily: root.fontFamily
                anchors.verticalCenter: parent.verticalCenter
              }
              Caption {
                text: "probed " + root.ageText
                anchors.verticalCenter: parent.verticalCenter
              }

              // Live marker: blinks once per ledger advance. It is a heartbeat
              // of the file, not a claim about anything in it.
              Rectangle {
                id: liveDot
                width: Style.space(8)
                height: width
                radius: width / 2
                color: root.accent
                opacity: 0.35
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation {
                  id: liveBlink
                  NumberAnimation { target: liveDot; property: "opacity"; to: 1; duration: 80 }
                  NumberAnimation { target: liveDot; property: "opacity"; to: 0.35; duration: 900; easing.type: Easing.OutCubic }
                }
                Connections {
                  target: jackal
                  function onLedgerAdvanced() { liveBlink.restart() }
                }
              }

              Button {
                iconText: "✕"
                tooltipText: "Close  (Esc)"
                foreground: root.foreground
                fontFamily: root.fontFamily
                iconSize: Style.font.body
                horizontalPadding: Style.space(8)
                verticalPadding: Style.space(5)
                bordered: true
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.dismiss()
              }
            }
          }

          Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

          // ------------------------------------------------------- decks
          StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.sectionIndex(root.section)

            OverviewSection {}
            LedgerSection {}
            GraphSection {}
            ProbesSection {}
            VerifySection {}
            RegisterSection {}
            ThothSection {}
          }

          // ------------------------------------------------- pinned laws
          // Outside every scroll area, because these are the lines that must
          // never be scrolled away.
          Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(14)

            Text {
              textFormat: Text.PlainText
              text: "ASSURANCE ≠ CONSEQUENCE"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.3
            }
            Caption {
              Layout.fillWidth: true
              text: "A ceiling is an upper bound, never a grant. Refusal is a first-class answer — "
                + "a refused question is answered, not retried on a weaker lane to obtain some number."
                + (jackal.nonClaim !== "" ? "   ·   NON-CLAIM  " + jackal.nonClaim : "")
              elide: Text.ElideRight
              wrapMode: Text.NoWrap
            }
            Caption {
              text: "1–7 decks · Tab · Shift+R probe · Shift+V verify · Esc"
            }
          }
        }
      }
    }
  }

  // ========================================================= OVERVIEW deck
  // Every account visible at once, none of them merged. Each card is a window
  // onto the same data the dedicated deck shows in full — never a score, and
  // never a promoted claim.

  component OverviewSection: Item {
    RowLayout {
      anchors.fill: parent
      spacing: Style.space(14)

      // ---- left: what the kernel has been doing ------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 62
        Layout.minimumWidth: 0
        spacing: Style.space(14)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)

          JkStat {
            Layout.fillWidth: true
            label: "Calls"
            value: String(root.summary.total)
            sub: "last " + Model.windowLabel(root.windowMs) + " · recall"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          JkStat {
            Layout.fillWidth: true
            label: "Refused"
            value: String(root.summary.refused)
            sub: root.summary.refused > 0 ? "named reasons" : "none in window"
            foreground: root.foreground
            tone: root.summary.refused > 0 ? root.urgent : root.foreground
            fontFamily: root.fontFamily
          }
          JkStat {
            Layout.fillWidth: true
            label: "Round trip"
            value: Model.formatMs(root.summary.medianMs)
            sub: root.summary.p90Ms >= 0 ? "median · p90 " + Model.formatMs(root.summary.p90Ms) : "median · wrapper timing"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          JkStat {
            Layout.fillWidth: true
            label: "Receipts"
            value: jackal.receiptCount >= 0 ? String(jackal.receiptCount) : "—"
            sub: "retained · re-verifiable"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          JkStat {
            Layout.fillWidth: true
            label: "Declared tools"
            value: jackal.declaredToolCount > 0 ? String(jackal.declaredToolCount) : "—"
            sub: jackal.epoch !== "" ? "inventory · " + jackal.epoch : "no runtime named"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
        }

        Card {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredHeight: 300
          title: "Activity"
          note: "calls per " + Model.windowLabel(root.activity.bucketMs) + " · recall, not evidence"

          JkTimeline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Style.space(110)
            series: root.activity
            foreground: root.foreground
            accent: root.accent
            urgent: root.urgent
            fontFamily: root.fontFamily
          }

          JkSpectrum {
            Layout.fillWidth: true
            histogram: root.histogram
            foreground: root.foreground
            accent: root.accent
            urgent: root.urgent
            fontFamily: root.fontFamily
          }
        }

        Card {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredHeight: 420
          title: "Latest answers"
          note: "newest first · recall, not evidence"

          Caption {
            visible: !root.newest
            Layout.fillWidth: true
            text: "No recorded answer yet. Rows appear here as the kernel is called."
          }

          JkResultRow {
            visible: !!root.newest
            Layout.fillWidth: true
            row: root.newest
            nowMs: jackal.nowMs
            foreground: root.foreground
            accentColor: root.accent
            urgent: root.urgent
            fontFamily: root.fontFamily
            fresh: root.newestFresh
            onClicked: root.selectSection("ledger")
          }

          Flickable {
            id: overviewFeed
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: overviewFeedColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
              id: overviewFeedColumn
              width: overviewFeed.width
              spacing: Style.space(2)

              Repeater {
                model: jackal.allResults.slice(1, 1 + Math.max(3, jackal.feedLimit))
                delegate: JkResultRow {
                  required property var modelData
                  width: overviewFeedColumn.width
                  row: modelData
                  nowMs: jackal.nowMs
                  compact: true
                  foreground: root.foreground
                  accentColor: root.accent
                  urgent: root.urgent
                  fontFamily: root.fontFamily
                  onClicked: root.selectSection("ledger")
                }
              }
            }
          }

          Row {
            Layout.fillWidth: true
            spacing: Style.space(10)
            Button {
              text: "Open the ledger"
              iconText: "󰈙"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              iconSize: Style.font.bodySmall
              onClicked: root.selectSection("ledger")
            }
            Caption {
              text: root.allSummary.allTotal + " rows on disk · " + root.allSummary.tools + " distinct tools · "
                + Model.countText(root.allSummary.refused, "refusal", "refusals")
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      // ---- right: the accounts that bound what any of it may decide ----------
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 38
        Layout.minimumWidth: 0
        spacing: Style.space(14)

        Card {
          Layout.fillWidth: true
          title: "Session function"
          note: "this shell session only"

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)

            Text {
              textFormat: Text.PlainText
              text: jackal.busy ? "PROBING…" : Model.stateLabel(root.evidenceState)
              color: root.stateColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              font.bold: true
              font.letterSpacing: 1.5
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.space(2)
              Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: jackal.probeTotal > 0 ? jackal.probePassed + " / " + jackal.probeTotal + " classes at class" : "not probed"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                elide: Text.ElideRight
              }
              Caption {
                Layout.fillWidth: true
                text: "one real tool per declared class · probed " + root.ageText
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
              }
            }
            Button {
              iconText: Model.GLYPH.refresh
              tooltipText: "Probe now  (Shift+R)"
              iconSpinning: jackal.busy
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconSize: Style.font.title
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(6)
              onClicked: jackal.refresh()
            }
          }

          Caption {
            visible: !root.affirmative
            Layout.fillWidth: true
            text: Model.stateBlurb(root.evidenceState, jackal.report)
            color: root.alarming ? root.urgent : root.faint
          }

          GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Style.space(14)
            rowSpacing: Style.space(4)

            Repeater {
              model: jackal.probeRows
              delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Style.space(8)
                Text {
                  textFormat: Text.PlainText
                  text: modelData.pass ? Model.GLYPH.pass : Model.GLYPH.fail
                  color: modelData.pass ? root.foreground : root.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: modelData.name
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
                Text {
                  textFormat: Text.PlainText
                  text: modelData.executed !== "" ? modelData.executed : "—"
                  color: modelData.pass ? root.faint : root.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
            }
          }
        }

        Card {
          Layout.fillWidth: true
          title: "Sealed runtime · THOTH"
          note: "one engine, one identity"

          JkKeyValue {
            Layout.fillWidth: true
            label: "Epoch"; value: jackal.epoch !== "" ? jackal.epoch : "—"
            foreground: root.foreground; fontFamily: root.fontFamily
          }
          JkKeyValue {
            Layout.fillWidth: true
            label: "Identity"
            value: jackal.report ? (jackal.identityMatch ? "match" : "unproven") : "—"
            tone: jackal.report ? (jackal.identityMatch ? root.foreground : root.urgent) : root.dim
            foreground: root.foreground; fontFamily: root.fontFamily
          }
          JkKeyValue {
            Layout.fillWidth: true
            label: "Package"
            value: jackal.packageSha !== "" ? Model.shortHash(jackal.packageSha) : "—"
            copyable: jackal.packageSha !== ""
            foreground: root.foreground; fontFamily: root.fontFamily
            onCopyRequested: jackal.copyText(jackal.packageSha, "package digest")
          }
          JkKeyValue {
            Layout.fillWidth: true
            label: "Runtime verify"
            value: jackal.verifyText !== "" ? jackal.verifyText : "not run this session"
            tone: jackal.verifyText === "" ? root.dim : (jackal.verifyText === "PASS" ? root.foreground : root.urgent)
            foreground: root.foreground; fontFamily: root.fontFamily
          }
          JkKeyValue {
            Layout.fillWidth: true
            label: "Z3 · Anubis"
            value: jackal.report
              ? (jackal.z3Present ? "z3 present" : "z3 absent") + " · "
                + (jackal.anubisPresent ? "compiler present" : "compiler absent")
              : "—"
            foreground: root.foreground; fontFamily: root.fontFamily
          }
          JkKeyValue {
            Layout.fillWidth: true
            label: "Host"; value: jackal.hostText !== "" ? jackal.hostText : "—"
            foreground: root.foreground; fontFamily: root.fontFamily
          }
        }

        Card {
          Layout.fillWidth: true
          Layout.fillHeight: true
          title: "Tools in use"
          note: root.allSummary.tools + " distinct · " + root.allSummary.allTotal + " rows on disk"

          Caption {
            visible: root.leaderboard.length === 0
            Layout.fillWidth: true
            text: "no calls recorded yet"
          }

          Repeater {
            model: root.leaderboard
            delegate: JkBarRow {
              required property var modelData
              Layout.fillWidth: true
              name: modelData.tool
              count: modelData.count
              refusedCount: modelData.refused
              share: modelData.share
              foreground: root.foreground
              accent: root.accent
              urgent: root.urgent
              fontFamily: root.fontFamily
            }
          }

          Item { Layout.fillHeight: true }
        }

        Card {
          Layout.fillWidth: true
          title: "Verify"
          note: "the one lane that acts"
          urgentEdge: !!jackal.verifyResult && Model.verifyIsAlarming(jackal.verifyResult)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            Button {
              text: jackal.verifyBusy ? "Verifying…" : "Verify clipboard"
              iconText: Model.GLYPH.verified
              enabled: !jackal.verifyBusy
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              iconSize: Style.font.body
              onClicked: jackal.verifyArtifact()
            }
            Body {
              Layout.fillWidth: true
              text: jackal.verifyResult
                ? Model.verifyStatusLabel(jackal.verifyResult.status) + " · " + Model.verifyRaisedByText(jackal.verifyResult)
                : (jackal.actionStatus !== "" ? jackal.actionStatus : "no artifact routed yet")
              color: jackal.verifyResult && Model.verifyIsAlarming(jackal.verifyResult) ? root.urgent : root.dim
              elide: Text.ElideRight
              wrapMode: Text.NoWrap
            }
          }
        }
      }
    }
  }

  // ========================================================== LEDGER deck
  // Local recall of returned answers, newest first, every row expandable to
  // the fields and non-claims the wrapper recorded. A retained receipt is
  // re-verified through the real front door in VERIFY — the row itself proves
  // nothing; it is a line this tooling wrote.

  component LedgerSection: Item {
    Card {
      anchors.fill: parent
      title: "Ledger — local recall"
      note: "recall, not evidence · ~/.local/state/jackal/results.jsonl"

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(10)

        Row {
          spacing: Style.space(4)
          Repeater {
            model: root.feedFilters
            delegate: Button {
              required property var modelData
              text: modelData.label + "  " + modelData.count
              selected: root.feedFilter === modelData.key
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              horizontalPadding: Style.space(10)
              verticalPadding: Style.space(5)
              onClicked: root.setFeedFilter(modelData.key)
            }
          }
        }
        Item { Layout.fillWidth: true }
        Caption {
          text: root.feed.length + " rows · j/k walk · Enter expands · "
            + "median " + Model.formatMs(root.allSummary.medianMs)
            + " · span " + Model.dayClockText(root.allSummary.oldestMs) + " → " + Model.dayClockText(root.allSummary.newestMs)
        }
      }

      ListView {
        id: feedList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: root.feed
        Component.onCompleted: root.feedView = feedList
        clip: true
        spacing: Style.space(2)
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        // Rows re-measure as they expand; cache a screenful so a walk stays smooth.
        cacheBuffer: 800

        delegate: JkResultRow {
          id: feedRow
          required property var modelData
          required property int index
          width: ListView.view.width - Style.space(10)
          row: modelData
          nowMs: jackal.nowMs
          foreground: root.foreground
          accentColor: root.accent
          urgent: root.urgent
          fontFamily: root.fontFamily
          expanded: root.feedExpanded === index
          hasCursor: root.feedCursor === index
          fresh: index === 0 && root.feedFilter === "all" && root.newestFresh
          onPointerMoved: function(x, y) { root.feedPointer(feedRow.index, feedRow, x, y) }
          onClicked: root.toggleFeedRow(index)
          onVerifyRequested: function(digest) {
            jackal.verifyReceiptDigest(digest)
            root.selectSection("verify")
          }
        }

        Caption {
          visible: root.feed.length === 0
          anchors.centerIn: parent
          text: root.feedFilter === "all"
            ? "no recorded results yet"
            : "no " + root.feedFilter + " rows in the ledger"
        }
      }
    }
  }

  // The sweep instrument, shared by the graph deck. Pixels are visualization,
  // never evidence, and the canvas says so on its face.
  component SweepPlot: Rectangle {
    id: plotFrame
    color: Util.alpha(root.foreground, 0.02)
    radius: Style.cornerRadius
    border.width: 1
    border.color: root.hairline
    clip: true

    Caption {
      anchors.centerIn: parent
      visible: jackal.graphPoints.length === 0 && !jackal.graphBusy
      text: jackal.graphError !== ""
        ? jackal.graphError
        : "no sweep yet — enter an expression and press SWEEP"
      color: jackal.graphError !== "" ? root.urgent : root.faint
      horizontalAlignment: Text.AlignHCenter
      width: plotFrame.width - Style.space(40)
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
        acceptedButtons: Qt.NoButton
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
          ctx.fillStyle = root.dim
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
        var top = 14
        var bottom = 26
        var plotW = Math.max(10, w - gutterL - 14)
        var plotH = Math.max(10, h - top - bottom)

        function sx(xv) {
          return gutterL + (xHi === xLo ? 0 : ((xv - xLo) / (xHi - xLo)) * plotW)
        }
        function sy(v) {
          return top + plotH - ((v - yMin) / (yMax - yMin)) * plotH
        }

        // Refused spans are painted, never silently skipped.
        var runs = Model.graphRefusedRuns(pts)
        ctx.fillStyle = Util.alpha(root.urgent, 0.14)
        for (var r = 0; r < runs.length; r++) {
          var bx0 = sx(runs[r].x0)
          var bx1 = sx(runs[r].x1)
          ctx.fillRect(bx0, top, Math.max(1, bx1 - bx0), plotH)
        }

        ctx.strokeStyle = Util.alpha(root.foreground, 0.10)
        ctx.lineWidth = 1
        ctx.fillStyle = root.faint
        for (var t = 0; t < yTicks.ticks.length; t++) {
          var yv = yTicks.ticks[t]
          if (yv < yMin || yv > yMax) continue
          var yy = Math.round(sy(yv)) + 0.5
          ctx.beginPath()
          ctx.moveTo(gutterL, yy)
          ctx.lineTo(gutterL + plotW, yy)
          ctx.stroke()
          var lbl = Model.graphTickLabel(yv, yTicks.step)
          ctx.fillText(lbl, gutterL - ctx.measureText(lbl).width - 6, yy + 3)
        }

        if (yMin < 0 && yMax > 0) {
          ctx.strokeStyle = Util.alpha(root.foreground, 0.30)
          ctx.beginPath()
          ctx.moveTo(gutterL, sy(0))
          ctx.lineTo(gutterL + plotW, sy(0))
          ctx.stroke()
        }

        // The curve. A refused sample lifts the pen: the line is never drawn
        // across a gap the evaluator declined to answer.
        ctx.strokeStyle = root.accent
        ctx.lineWidth = 2
        ctx.lineJoin = "round"
        ctx.beginPath()
        var drawing = false
        for (var i = 0; i < pts.length; i++) {
          var pt = pts[i]
          if (!pt || pt.y === null || !isFinite(pt.y)) { drawing = false; continue }
          if (!drawing) { ctx.moveTo(sx(pt.x), sy(pt.y)); drawing = true }
          else ctx.lineTo(sx(pt.x), sy(pt.y))
        }
        ctx.stroke()

        ctx.fillStyle = root.faint
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
          ctx.strokeStyle = Util.alpha(root.foreground, 0.35)
          ctx.lineWidth = 1
          ctx.beginPath()
          ctx.moveTo(hx, top)
          ctx.lineTo(hx, top + plotH)
          ctx.stroke()
          if (hp.y !== null && isFinite(hp.y)) {
            ctx.fillStyle = root.foreground
            ctx.beginPath()
            ctx.arc(hx, sy(hp.y), 3, 0, Math.PI * 2)
            ctx.fill()
          }
          var ht = Model.graphHoverText(hp, idx, pts.length)
          ctx.fillStyle = root.foreground
          var tw = ctx.measureText(ht).width
          var tx = Math.min(gutterL + plotW - tw, Math.max(gutterL, hx + 8))
          ctx.fillText(ht, tx, top + 4)
        }
      }
    }
  }

  // =========================================================== GRAPH deck

  component GraphSection: Item {
    id: graphSection

    RowLayout {
      anchors.fill: parent
      spacing: Style.space(14)

      Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Graph deck — live sweep"
        note: "graph pixels are visualization, never evidence"

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)
          JkChip {
            label: jackal.graphBusy ? "SWEEPING…" : "SEALED EVALUATOR · f64"
            tone: root.foreground
            dot: jackal.graphBusy
            fontFamily: root.fontFamily
          }
          JkChip {
            label: "status=estimated visualization"
            tone: root.dim
            fontFamily: root.fontFamily
          }
          Caption {
            Layout.fillWidth: true
            text: jackal.graphMeta
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
          }
        }

        SweepPlot {
          Layout.fillWidth: true
          Layout.fillHeight: true
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Caption { text: "f(x)" }
          TextField {
            id: exprField
            Layout.fillWidth: true
            text: jackal.graphExpression
            placeholderText: "x^6-5*x^4+4*x^2"
            foreground: root.foreground
            accent: root.accent
            font.family: root.fontFamily
            onAccepted: jackal.plotGraph(exprField.text, loField.text, hiField.text)
          }
          Caption { text: "lo" }
          TextField {
            id: loField
            Layout.preferredWidth: Style.space(96)
            text: jackal.graphXMin
            foreground: root.foreground
            accent: root.accent
            font.family: root.fontFamily
            onAccepted: jackal.plotGraph(exprField.text, loField.text, hiField.text)
          }
          Caption { text: "hi" }
          TextField {
            id: hiField
            Layout.preferredWidth: Style.space(96)
            text: jackal.graphXMax
            foreground: root.foreground
            accent: root.accent
            font.family: root.fontFamily
            onAccepted: jackal.plotGraph(exprField.text, loField.text, hiField.text)
          }
          Button {
            text: jackal.graphBusy ? "Sweeping…" : "Sweep"
            iconText: "󰐊"
            enabled: !jackal.graphBusy
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            iconSize: Style.font.body
            onClicked: jackal.plotGraph(exprField.text, loField.text, hiField.text)
          }
        }

        Caption {
          Layout.fillWidth: true
          text: "Exact rational x grid · f64 samples from the runtime's own evaluator · "
            + "a refused sample breaks the curve · pixels are not proof of continuity, "
            + "roots, extrema, or anything between samples."
        }
      }

      Card {
        Layout.preferredWidth: Style.space(300)
        Layout.fillHeight: true
        title: "Presets"

        Repeater {
          model: [
            { label: "sextic well", expr: "x^6-5*x^4+4*x^2", lo: "-2.6", hi: "2.6" },
            { label: "damped wave", expr: "sin(x)/x", lo: "-18", hi: "18" },
            { label: "gaussian", expr: "exp(-x^2)", lo: "-3", hi: "3" },
            { label: "tanh gate", expr: "tanh(x)", lo: "-4", hi: "4" },
            { label: "log edge", expr: "ln(x)", lo: "-1", hi: "6" },
            { label: "pole", expr: "1/(x-1)", lo: "-2", hi: "4" }
          ]
          delegate: Button {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.label + "   " + modelData.expr
            leftAlign: true
            selected: jackal.graphExpression === modelData.expr
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            horizontalPadding: Style.space(10)
            verticalPadding: Style.space(7)
            onClicked: {
              exprField.text = modelData.expr
              loField.text = modelData.lo
              hiField.text = modelData.hi
              jackal.plotGraph(modelData.expr, modelData.lo, modelData.hi)
            }
          }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

        JkSectionTitle {
          Layout.fillWidth: true
          title: "THOTH · HELLGATE"
          note: "reference render"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Image {
          Layout.fillWidth: true
          Layout.preferredHeight: width * 0.6
          source: Qt.resolvedUrl("assets/jackal-thoth-hellgate-graph.png")
          fillMode: Image.PreserveAspectFit
          smooth: true
          asynchronous: true
          opacity: 0.88
        }

        Caption {
          Layout.fillWidth: true
          text: "The HELLGATE lane returns bounded, not formal-bounded. "
            + "This render is a picture of a result, not the result."
        }

        Item { Layout.fillHeight: true }
      }
    }
  }

  // ========================================================== PROBES deck

  component ProbesSection: Item {
    Card {
      anchors.fill: parent
      title: "Session function — live probes"
      note: "established only by tools executed in this shell session"

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(10)
        JkStat {
          Layout.fillWidth: true
          label: "Doctor verdict"
          value: jackal.busy ? "PROBING…" : (jackal.verdict !== "" ? jackal.verdict : "—")
          sub: "probed " + root.ageText
          tone: root.stateColor
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Classes at class"
          value: jackal.probeTotal > 0 ? jackal.probePassed + " / " + jackal.probeTotal : "—"
          sub: "one real tool per declared class"
          tone: jackal.probeTotal > 0 && jackal.probePassed === jackal.probeTotal ? root.foreground : root.urgent
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Z3"
          value: jackal.report ? (jackal.z3Present ? "present" : "absent") : "—"
          sub: "program-verifier dependency"
          tone: jackal.z3Present ? root.foreground : root.dim
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Anubis compiler"
          value: jackal.report ? (jackal.anubisPresent ? "present" : "absent") : "—"
          sub: "check-program dependency"
          tone: jackal.anubisPresent ? root.foreground : root.dim
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        Button {
          text: jackal.busy ? "Probing…" : "Probe now"
          iconText: Model.GLYPH.refresh
          iconSpinning: jackal.busy
          enabled: !jackal.busy
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          iconSize: Style.font.body
          Layout.alignment: Qt.AlignVCenter
          onClicked: jackal.refresh()
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(10)
        ColumnHead { Layout.preferredWidth: Style.space(160); text: "CLASS" }
        ColumnHead { Layout.fillWidth: true; text: "TOOL EXECUTED" }
        ColumnHead { Layout.preferredWidth: Style.space(170); text: "EXECUTED" }
        ColumnHead { Layout.preferredWidth: Style.space(170); text: "DECLARED" }
        ColumnHead { Layout.preferredWidth: Style.space(40); text: "" }
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: probeColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: probeColumn
          width: parent.width
          spacing: Style.space(3)

          Caption {
            visible: jackal.probeRows.length === 0
            text: jackal.busy ? "probing…" : "nothing established yet — probe to execute one tool per declared class"
          }

          Repeater {
            model: jackal.probeRows
            delegate: CursorSurface {
              required property var modelData
              width: probeColumn.width
              implicitHeight: probeLine.implicitHeight + Style.space(14)
              foreground: root.foreground
              bordered: true
              RowLayout {
                id: probeLine
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(10)
                Text {
                  textFormat: Text.PlainText
                  Layout.preferredWidth: Style.space(150)
                  text: modelData.name
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: modelData.tool
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }
                JkChip {
                  Layout.preferredWidth: Style.space(160)
                  label: modelData.executed !== "" ? modelData.executed : "—"
                  tone: modelData.pass ? root.foreground : root.urgent
                  fontFamily: root.fontFamily
                }
                JkChip {
                  Layout.preferredWidth: Style.space(160)
                  label: modelData.expected !== "" ? modelData.expected : "—"
                  tone: root.dim
                  fontFamily: root.fontFamily
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.preferredWidth: Style.space(30)
                  horizontalAlignment: Text.AlignHCenter
                  text: modelData.pass ? Model.GLYPH.pass : Model.GLYPH.fail
                  color: modelData.pass ? root.foreground : root.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                }
              }
            }
          }
        }
      }

      Column {
        Layout.fillWidth: true
        spacing: Style.space(3)
        Repeater {
          model: jackal.report && Array.isArray(jackal.report.non_claims) ? jackal.report.non_claims : []
          delegate: Caption {
            required property var modelData
            width: parent.width
            text: "non-claim · " + modelData
          }
        }
      }
    }
  }

  // ========================================================== VERIFY deck

  component VerifySection: Item {
    Card {
      anchors.fill: parent
      title: "Verify — clipboard artifact"
      note: "the one section that acts"
      urgentEdge: !!jackal.verifyResult && Model.verifyIsAlarming(jackal.verifyResult)

      Body {
        Layout.fillWidth: true
        text: "Copy a JACKAL receipt or claim bundle, then verify. Expectations come from "
          + "the operator's file, never from the artifact under review. If verification "
          + "refuses because the expectations do not authorize that request, that is correct — "
          + "widening the authorization is a deliberate operator edit, never something done "
          + "to make a check pass."
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(10)

        Button {
          text: jackal.verifyBusy ? "Verifying…" : "Verify clipboard artifact"
          iconText: Model.GLYPH.verified
          enabled: !jackal.verifyBusy
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.body
          iconSize: Style.font.title
          horizontalPadding: Style.space(14)
          verticalPadding: Style.space(9)
          onClicked: jackal.verifyArtifact()
        }
        Button {
          text: "Runtime verify"
          iconText: "󰑐"
          tooltipText: "Run the core provisioner's pinned tree check"
          enabled: !jackal.busy
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          iconSize: Style.font.body
          onClicked: jackal.runVerify()
        }
        Item { Layout.fillWidth: true }
        JkChip {
          label: "RUNTIME " + (jackal.runtimeDir !== "" ? "BOUND" : "UNBOUND")
          tone: jackal.runtimeDir !== "" ? root.foreground : root.dim
          fontFamily: root.fontFamily
        }
        JkChip {
          visible: jackal.verifyText !== ""
          label: "TREE " + jackal.verifyText
          tone: jackal.verifyText === "PASS" ? root.foreground : root.urgent
          fontFamily: root.fontFamily
        }
      }

      JkKeyValue {
        Layout.fillWidth: true
        label: "Authorized by you"
        value: jackal.expectationsPath
        copyable: true
        foreground: root.foreground; fontFamily: root.fontFamily
        onCopyRequested: function(t) { jackal.copyText(t, "expectations path") }
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Runtime"
        value: jackal.runtimeDir !== "" ? jackal.runtimeDir : "—"
        foreground: root.foreground; fontFamily: root.fontFamily
      }

      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.space(14)

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 60
        contentWidth: width
        contentHeight: verdictColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: verdictColumn
          width: parent.width
          spacing: Style.space(8)

          Caption {
            visible: !jackal.verifyResult
            width: parent.width
            text: jackal.actionStatus !== ""
              ? jackal.actionStatus
              : "no artifact routed yet — copy a receipt or bundle, then verify"
          }

          Text {
            visible: !!jackal.verifyResult
            textFormat: Text.PlainText
            text: Model.verifyStatusLabel(jackal.verifyResult ? jackal.verifyResult.status : "")
            color: jackal.verifyResult && Model.verifyIsAlarming(jackal.verifyResult)
              ? root.urgent
              : (jackal.verifyResult && Model.verifyIsAffirmative(jackal.verifyResult) ? root.foreground : root.dim)
            font.family: root.fontFamily
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            font.letterSpacing: 2
          }
          Body {
            visible: !!jackal.verifyResult
            width: parent.width
            text: Model.verifySubject(jackal.verifyResult)
          }
          Body {
            visible: !!jackal.verifyResult && Model.verifyIsRefusal(jackal.verifyResult)
            width: parent.width
            text: Model.verifyRaisedByText(jackal.verifyResult)
              + (jackal.verifyResult && jackal.verifyResult.reason ? " · " + jackal.verifyResult.reason : "")
              + (jackal.verifyResult && jackal.verifyResult.detail ? " — " + jackal.verifyResult.detail : "")
            color: Model.verifyIsAlarming(jackal.verifyResult) ? root.urgent : root.dim
          }

          JkSectionTitle {
            visible: !!jackal.verifyResult && Model.authorizedRows(jackal.verifyResult).length > 0
            width: parent.width
            title: "Authorized expectations"
            note: "from the operator's file"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          Repeater {
            model: Model.authorizedRows(jackal.verifyResult)
            delegate: JkKeyValue {
              required property var modelData
              width: parent.width
              label: modelData.name
              value: modelData.value
              foreground: root.foreground
              fontFamily: root.fontFamily
              wrap: true
            }
          }
        }
      }

      // The receipts the wrapper has retained on disk. Each one can go back
      // through the same front door, against the same operator-owned
      // authorization; a refusal there is the correct answer, not a fault.
      Card {
        Layout.fillHeight: true
        Layout.preferredWidth: 40
        Layout.fillWidth: true
        title: "Retained receipts"
        note: (jackal.receiptCount >= 0 ? jackal.receiptCount : "—") + " on disk · newest first"

        Caption {
          visible: jackal.receiptDigests.length === 0
          Layout.fillWidth: true
          text: "no receipts retained yet — a formal lane writes one here"
        }

        ListView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: jackal.receiptDigests
          clip: true
          spacing: Style.space(2)
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          delegate: CursorSurface {
            id: receiptRow
            required property var modelData
            required property int index
            readonly property bool current: !!jackal.verifyResult
              && String(jackal.verifyResult.artifact_sha256 || "").indexOf(modelData) === 0
            width: ListView.view.width - Style.space(10)
            implicitHeight: receiptLine.implicitHeight + Style.space(12)
            foreground: root.foreground
            hasCursor: receiptMouse.containsMouse

            RowLayout {
              id: receiptLine
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(6)
              spacing: Style.space(10)
              Text {
                textFormat: Text.PlainText
                text: Model.GLYPH.verified
                color: receiptRow.current ? root.foreground : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
              Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: Model.shortHash(receiptRow.modelData)
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideMiddle
              }
              Button {
                text: jackal.verifyBusy ? "…" : "Re-verify"
                enabled: !jackal.verifyBusy
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                horizontalPadding: Style.space(8)
                verticalPadding: Style.space(3)
                onClicked: jackal.verifyReceiptDigest(receiptRow.modelData)
              }
            }

            MouseArea {
              id: receiptMouse
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
              z: -1
            }
          }
        }
      }
      }
    }
  }

  // ======================================================== REGISTER deck

  component RegisterSection: Item {
    Card {
      anchors.fill: parent
      title: "Evidence register — capability"
      note: "both axes, never merged into a score · " + (jackal.declaredToolCount > 0 ? jackal.declaredToolCount + " declared tools" : "inventory not loaded")

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(10)
        ColumnHead { Layout.preferredWidth: Style.space(170); text: "FAMILY" }
        ColumnHead { Layout.preferredWidth: Style.space(300); text: "ASSURANCE" }
        ColumnHead { Layout.preferredWidth: Style.space(190); text: "CONSEQUENCE CEILING" }
        ColumnHead { Layout.preferredWidth: Style.space(50); text: "TOOLS" }
        ColumnHead { Layout.fillWidth: true; text: "WHAT STANDS BEHIND AN ANSWER" }
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: registerColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: registerColumn
          width: parent.width - Style.space(10)
          spacing: Style.space(3)

          Caption {
            visible: jackal.familyRows.length === 0
            text: "capability inventory not loaded"
          }

          Repeater {
            model: jackal.familyRows
            delegate: CursorSurface {
              required property var modelData
              width: registerColumn.width
              implicitHeight: famLine.implicitHeight + Style.space(14)
              foreground: root.foreground
              bordered: true
              RowLayout {
                id: famLine
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(10)
                Text {
                  textFormat: Text.PlainText
                  Layout.preferredWidth: Style.space(160)
                  text: modelData.family
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.preferredWidth: Style.space(290)
                  text: modelData.assurance
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }
                Row {
                  Layout.preferredWidth: Style.space(180)
                  spacing: Style.space(6)
                  Text {
                    textFormat: Text.PlainText
                    text: modelData.consequence
                    color: modelData.consequenceDeclared ? root.dim : root.faint
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, Style.space(150))
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    // arrow-to-line: a consequence held at its ceiling, strictly
                    // below the assurance. The anti-laundering boundary, marked.
                    visible: modelData.capped
                    textFormat: Text.PlainText
                    text: Model.GLYPH.capped
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.preferredWidth: Style.space(40)
                  text: String(modelData.toolCount)
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: modelData.backing !== "" ? modelData.backing : "—"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
            }
          }

          Item { width: 1; height: Style.space(10) }

          JkSectionTitle {
            width: parent.width
            title: "Agent surface"
            note: "which tools a profile exposes — the operator's lever"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Repeater {
            model: jackal.profileRows
            delegate: RowLayout {
              required property var modelData
              width: registerColumn.width
              spacing: Style.space(10)
              JkChip {
                Layout.preferredWidth: Style.space(100)
                label: modelData.name.toUpperCase() + "  " + modelData.count
                tone: root.foreground
                fontFamily: root.fontFamily
              }
              Body {
                Layout.fillWidth: true
                text: modelData.meaning
              }
            }
          }

          Caption {
            visible: !jackal.everyToolDeclaresRefused && jackal.inventory !== null
            width: parent.width
            color: root.urgent
            text: "Tools that do not declare `refused`: " + jackal.toolsWithoutRefused.join(", ")
          }
        }
      }
    }
  }

  // =========================================================== THOTH deck

  component ThothSection: Item {
    Card {
      anchors.fill: parent
      title: "Integrated THOTH — sealed runtime"
      note: "one engine, one identity"

      Body {
        Layout.fillWidth: true
        text: "THOTH lives inside JACKAL as its identity-pinned measurement/provenance "
          + "subsystem — not a separate service. Exact-given remains conditional on its "
          + "given datum. Everything on this deck was read from the runtime the doctor "
          + "probe named, or from the ledger; nothing is typed in."
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(10)
        JkStat {
          Layout.fillWidth: true
          label: "Runtime epoch"
          value: jackal.epoch !== "" ? jackal.epoch : "—"
          sub: "package located by the operator CLI"
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Identity"
          value: jackal.report ? (jackal.identityMatch ? "match" : "unproven") : "—"
          sub: "locator ↔ package fields"
          tone: jackal.report ? (jackal.identityMatch ? root.foreground : root.urgent) : root.dim
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Declared tools"
          value: jackal.declaredToolCount > 0 ? String(jackal.declaredToolCount) : "—"
          sub: "capability_inventory_v1.json"
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Tools observed"
          value: String(root.allSummary.tools)
          sub: "distinct in the ledger · recall"
          foreground: root.foreground; fontFamily: root.fontFamily
        }
        JkStat {
          Layout.fillWidth: true
          label: "Receipts retained"
          value: jackal.receiptCount >= 0 ? String(jackal.receiptCount) : "—"
          sub: "content-addressed on disk"
          foreground: root.foreground; fontFamily: root.fontFamily
        }
      }

      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

      JkKeyValue {
        Layout.fillWidth: true
        label: "Package SHA-256"
        value: jackal.packageSha !== "" ? jackal.packageSha : "—"
        copyable: jackal.packageSha !== ""
        foreground: root.foreground; fontFamily: root.fontFamily
        onCopyRequested: jackal.copyText(jackal.packageSha, "package digest")
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Catalog SHA-256"
        value: jackal.catalogSha !== "" ? jackal.catalogSha : "—"
        copyable: jackal.catalogSha !== ""
        foreground: root.foreground; fontFamily: root.fontFamily
        onCopyRequested: jackal.copyText(jackal.catalogSha, "catalog digest")
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Inventory SHA-256"
        value: jackal.report && jackal.report.capability && jackal.report.capability.inventory_sha256
          ? String(jackal.report.capability.inventory_sha256) : "—"
        foreground: root.foreground; fontFamily: root.fontFamily
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Doctor runtime"
        value: jackal.doctorRuntimePath !== "" ? jackal.doctorRuntimePath : "—"
        foreground: root.foreground; fontFamily: root.fontFamily
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Provisioner"
        value: jackal.verifyReport && jackal.verifyReport.provisioner ? String(jackal.verifyReport.provisioner) : "run Runtime verify to name it"
        tone: jackal.verifyReport && jackal.verifyReport.provisioner ? root.foreground : root.faint
        foreground: root.foreground; fontFamily: root.fontFamily
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Host"
        value: jackal.hostText !== "" ? jackal.hostText : "—"
        foreground: root.foreground; fontFamily: root.fontFamily
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Every tool declares refused"
        value: jackal.inventory === null ? "—" : (jackal.everyToolDeclaresRefused ? "yes — observed on these exact bytes" : "no: " + jackal.toolsWithoutRefused.join(", "))
        tone: jackal.inventory === null ? root.dim : (jackal.everyToolDeclaresRefused ? root.foreground : root.urgent)
        foreground: root.foreground; fontFamily: root.fontFamily
      }
      JkKeyValue {
        Layout.fillWidth: true
        label: "Governing non-claim"
        value: jackal.nonClaim !== "" ? jackal.nonClaim : "—"
        copyable: jackal.nonClaim !== ""
        foreground: root.foreground; fontFamily: root.fontFamily
        wrap: true
        onCopyRequested: jackal.copyText(jackal.nonClaim, "non-claim")
      }

      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.hairline }

      JkSectionTitle {
        Layout.fillWidth: true
        title: "Non-claims"
        note: "what the doctor and the runtime verifier refuse to imply"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: nonClaimColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: nonClaimColumn
          width: parent.width
          spacing: Style.space(3)
          Repeater {
            model: {
              var out = []
              if (jackal.report && Array.isArray(jackal.report.non_claims))
                for (var i = 0; i < jackal.report.non_claims.length; i++) out.push("doctor · " + jackal.report.non_claims[i])
              if (jackal.verifyReport && Array.isArray(jackal.verifyReport.non_claims))
                for (var j = 0; j < jackal.verifyReport.non_claims.length; j++) out.push("verify · " + jackal.verifyReport.non_claims[j])
              return out
            }
            delegate: Caption {
              required property var modelData
              width: parent.width
              text: modelData
            }
          }
        }
      }
    }
  }
}
