import QtQuick
import qs.Commons
import qs.Ui

// A stat tile: a small-caps label, one large value, one line of standing.
// The value is printed as handed over; the sub line is where the caller says
// what kind of number it is (a count of ledger rows, a timing, a declaration).
BorderSurface {
  id: root

  property string label: ""
  property string value: ""
  property string sub: ""
  property color foreground: Color.foreground
  property color tone: foreground
  property string fontFamily: Style.font.family
  property real valueSize: Style.font.display

  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property color faint: Util.alpha(foreground, 0.46)

  implicitHeight: col.implicitHeight + Style.space(22)
  radius: Style.cornerRadius
  color: Util.alpha(root.foreground, 0.035)
  borderSpec: Border.flat(Util.alpha(root.foreground, 0.10), 1)

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(14)
    anchors.rightMargin: Style.space(14)
    spacing: Style.space(2)

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.label.toUpperCase()
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.2
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.value
      color: root.tone
      font.family: root.fontFamily
      font.pixelSize: root.valueSize
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      visible: root.sub !== ""
      width: parent.width
      text: root.sub
      color: root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }
}
