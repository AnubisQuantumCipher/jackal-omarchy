import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// One ledger row. Status chip in JACKAL's own word, the tool, when, how long,
// what was asked and what came back. A refusal carries its named reason in the
// refusal colour; an answer carries the engine's own line in the ordinary
// text colour — no class is promoted by tint. `expanded` opens the returned
// fields, the full arguments and the non-claims verbatim.
//
// JOP-UI-001: returned assurance vocabulary is rendered without promotion.
CursorSurface {
  id: root

  property var row: null
  property double nowMs: Date.now()
  property color accentColor: Color.accent
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  property bool compact: false
  property bool expanded: false
  property bool fresh: false
  property bool showRail: true

  signal clicked()
  signal hovered(bool isHovered)
  signal verifyRequested(string digest)

  readonly property bool refused: !!(row && row.refused)
  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property color faint: Util.alpha(foreground, 0.46)
  readonly property string statusText: row ? String(row.status || "—") : "—"
  readonly property string toolText: row ? String(row.tool || "") : ""
  readonly property string requestText: row ? String(row.request || "") : ""
  readonly property string detailText: row ? String(row.detail || "") : ""
  readonly property string digest: row ? String(row.digest || "") : ""
  readonly property bool retained: !!(row && row.retained)
  readonly property real padY: Style.space(compact ? 6 : 9)

  implicitHeight: body.implicitHeight + padY * 2

  Rectangle {
    visible: root.showRail
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: Style.space(5)
    anchors.bottomMargin: Style.space(5)
    width: Style.space(2)
    radius: 1
    color: root.refused ? root.urgent : (root.fresh ? root.accentColor : Util.alpha(root.foreground, 0.12))
    Behavior on color { ColorAnimation { duration: 300 } }
  }

  Column {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(root.showRail ? 12 : 8)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(3)

    Item {
      width: parent.width
      implicitHeight: headRow.implicitHeight

      Row {
        id: headRow
        spacing: Style.space(8)
        anchors.left: parent.left
        anchors.right: trailing.left
        anchors.rightMargin: Style.space(8)

        JkChip {
          label: root.statusText
          tone: root.refused ? root.urgent : root.foreground
          fontFamily: root.fontFamily
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          textFormat: Text.PlainText
          text: root.toolText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          elide: Text.ElideMiddle
          width: Math.min(implicitWidth, Math.max(Style.space(60), headRow.width - Style.space(96)))
          anchors.verticalCenter: parent.verticalCenter
        }
        JkChip {
          visible: root.digest !== ""
          label: root.retained ? "RECEIPT RETAINED" : "RECEIPT GONE"
          tone: root.retained ? root.foreground : root.urgent
          fontFamily: root.fontFamily
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Row {
        id: trailing
        spacing: Style.space(8)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Text {
          textFormat: Text.PlainText
          visible: root.row && root.row.roundTripMs >= 0 && !root.compact
          text: root.row ? Model.formatMs(root.row.roundTripMs) : ""
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          textFormat: Text.PlainText
          text: root.row ? Model.ageText(root.row.atMs, root.nowMs) : ""
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: root.requestText !== "" && !(root.compact && root.detailText !== "")
      width: parent.width
      text: root.requestText
      color: root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      visible: root.detailText !== ""
      width: parent.width
      text: root.detailText
      color: root.refused ? root.urgent : root.dim
      font.family: root.fontFamily
      font.pixelSize: root.compact ? Style.font.caption : Style.font.bodySmall
      wrapMode: root.compact ? Text.NoWrap : Text.Wrap
      elide: Text.ElideRight
      maximumLineCount: root.expanded ? 12 : (root.compact ? 1 : 2)
    }

    // ---- expanded: everything the wrapper recorded, verbatim ---------------
    Column {
      visible: root.expanded && root.row !== null
      width: parent.width
      spacing: Style.space(6)
      topPadding: Style.space(6)

      Rectangle { width: parent.width; height: 1; color: Util.alpha(root.foreground, 0.10) }

      Text {
        textFormat: Text.PlainText
        visible: root.row && root.row.assurance !== ""
        width: parent.width
        text: root.row ? "assurance · " + root.row.assurance : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
      }

      Repeater {
        model: root.row ? root.row.args : []
        delegate: JkKeyValue {
          required property var modelData
          width: parent.width
          label: "arg " + modelData.key
          value: modelData.value
          foreground: root.foreground
          fontFamily: root.fontFamily
          wrap: true
        }
      }

      Repeater {
        model: root.row ? root.row.fields : []
        delegate: JkKeyValue {
          required property var modelData
          width: parent.width
          label: modelData.key
          value: modelData.value
          foreground: root.foreground
          fontFamily: root.fontFamily
          wrap: true
        }
      }

      Repeater {
        model: root.row ? root.row.nonClaims : []
        delegate: Text {
          required property var modelData
          textFormat: Text.PlainText
          width: parent.width
          text: "non-claim · " + modelData
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.Wrap
        }
      }

      Row {
        visible: root.digest !== ""
        spacing: Style.space(8)
        Button {
          text: root.retained ? "Re-verify retained receipt" : "Receipt not retained"
          enabled: root.retained
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.caption
          onClicked: root.verifyRequested(root.digest)
        }
        Text {
          textFormat: Text.PlainText
          text: Model.shortHash(root.digest)
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: root.clicked()
  }
}
