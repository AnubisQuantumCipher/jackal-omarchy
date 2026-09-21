import QtQuick
import qs.Commons

// Leaderboard row: a name, its count, and a track filled in proportion to the
// busiest entry. Refusals ride along as a second number, never folded in.
Item {
  id: root

  property string name: ""
  property int count: 0
  property int refusedCount: 0
  property real share: 0
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family

  readonly property color dim: Qt.darker(foreground, 1.4)

  implicitHeight: nameText.implicitHeight + Style.space(9)

  Text {
    id: nameText
    textFormat: Text.PlainText
    anchors.left: parent.left
    anchors.right: countRow.left
    anchors.rightMargin: Style.space(8)
    anchors.top: parent.top
    text: root.name
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideMiddle
  }

  Row {
    id: countRow
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.space(6)

    Text {
      textFormat: Text.PlainText
      visible: root.refusedCount > 0
      text: root.refusedCount + " refused"
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      textFormat: Text.PlainText
      text: String(root.count)
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Rectangle {
    id: track
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Style.space(3)
    color: Util.alpha(root.foreground, 0.08)

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: Math.max(root.share > 0 ? Style.space(3) : 0, Math.round(track.width * Math.min(1, root.share)))
      color: root.accent
      Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }
  }
}
