import QtQuick
import qs.Commons
import qs.Ui

// A label/value line. Values that are worth carrying elsewhere (a digest, a
// path) are `copyable`; the copy goes out through the caller's one clipboard
// path so nothing leaves a surface unaccounted for.
Item {
  id: root

  property string label: ""
  property string value: ""
  property color foreground: Color.foreground
  property color tone: foreground
  property string fontFamily: Style.font.family
  property real labelWidth: Style.space(132)
  property bool copyable: false
  property bool wrap: false

  signal copyRequested(string text)

  readonly property color dim: Qt.darker(foreground, 1.4)

  implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

  Text {
    id: labelText
    textFormat: Text.PlainText
    anchors.left: parent.left
    anchors.top: parent.top
    width: root.labelWidth
    text: root.label.toUpperCase()
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.letterSpacing: 0.8
    elide: Text.ElideRight
  }

  Text {
    id: valueText
    textFormat: Text.PlainText
    anchors.left: labelText.right
    anchors.leftMargin: Style.space(10)
    anchors.right: parent.right
    anchors.top: parent.top
    text: root.value
    color: root.tone
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: root.wrap ? Text.ElideNone : Text.ElideMiddle
    wrapMode: root.wrap ? Text.WrapAnywhere : Text.NoWrap
    maximumLineCount: root.wrap ? 4 : 1
  }

  MouseArea {
    id: copyMouse
    anchors.fill: valueText
    enabled: root.copyable && root.value !== ""
    hoverEnabled: enabled
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.copyRequested(root.value)
  }

  PanelToolTip {
    visible: copyMouse.enabled && copyMouse.containsMouse
    text: "Copy"
    fontFamily: root.fontFamily
  }
}
