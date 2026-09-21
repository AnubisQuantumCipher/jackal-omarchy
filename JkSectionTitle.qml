import QtQuick
import qs.Commons

// A section title in the kit's small-caps voice: label, hairline, optional
// note at the trailing edge. The note is where a surface states the standing
// of what follows ("recall, not evidence") so the boundary sits on the title
// line rather than in a footnote nobody reads.
Item {
  id: root

  property string title: ""
  property string note: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property color faint: Util.alpha(foreground, 0.46)

  implicitHeight: Math.max(label.implicitHeight, noteText.implicitHeight)
  implicitWidth: label.implicitWidth + Style.space(24) + (noteText.visible ? noteText.implicitWidth : 0)

  Text {
    id: label
    textFormat: Text.PlainText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: root.title.toUpperCase()
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 1.3
  }

  Rectangle {
    anchors.left: label.right
    anchors.leftMargin: Style.space(10)
    anchors.right: noteText.visible ? noteText.left : parent.right
    anchors.rightMargin: noteText.visible ? Style.space(10) : 0
    anchors.verticalCenter: parent.verticalCenter
    height: 1
    color: Util.alpha(root.foreground, 0.10)
  }

  Text {
    id: noteText
    visible: root.note !== ""
    textFormat: Text.PlainText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, Math.max(0, root.width - label.implicitWidth - Style.space(40)))
    text: root.note
    color: root.faint
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    elide: Text.ElideRight
  }
}
