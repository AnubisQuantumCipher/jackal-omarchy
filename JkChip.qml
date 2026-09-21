import QtQuick
import qs.Commons
import qs.Ui

// A status chip. The label is printed in whatever vocabulary the caller hands
// it — an assurance class, a verdict, a count — and the tone is the caller's
// state colour. The chip never picks a colour of its own.
BorderSurface {
  id: root

  property string label: ""
  property color tone: Color.foreground
  property bool dot: false
  property bool solid: false
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.caption

  implicitWidth: row.implicitWidth + Style.space(12)
  implicitHeight: row.implicitHeight + Style.space(6)
  radius: Style.cornerRadius
  color: root.solid ? Util.alpha(root.tone, 0.16) : Util.alpha(root.tone, 0.07)
  borderSpec: Border.flat(Util.alpha(root.tone, 0.36), 1)

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Rectangle {
      visible: root.dot
      width: Style.space(6)
      height: width
      radius: width / 2
      color: root.tone
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      textFormat: Text.PlainText
      text: root.label
      color: root.tone
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      font.bold: true
      font.letterSpacing: 0.8
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
