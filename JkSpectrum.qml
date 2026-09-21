import QtQuick
import qs.Commons

// Status spectrum: one segment per status class the ledger holds, sized by
// count, each named beside its number. Classes are never merged into a score;
// refusals keep the refusal colour and everything else shares one hue so no
// answer class reads as "greener" than another.
Item {
  id: root

  property var histogram: []
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family

  readonly property color dim: Qt.darker(foreground, 1.4)
  readonly property int count: histogram ? histogram.length : 0

  implicitHeight: col.implicitHeight

  Column {
    id: col
    width: parent.width
    spacing: Style.space(8)

    Row {
      id: bar
      width: parent.width
      height: Style.space(8)
      spacing: Style.space(2)
      readonly property real usable: Math.max(0, width - spacing * Math.max(0, root.count - 1))

      Repeater {
        model: root.histogram
        delegate: Rectangle {
          required property var modelData
          required property int index
          height: bar.height
          width: Math.max(Style.space(3), Math.round(bar.usable * modelData.share))
          radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, height / 2) : 0
          color: modelData.refused
            ? root.urgent
            : Util.alpha(root.accent, Math.max(0.28, 0.92 - index * 0.18))
        }
      }
    }

    Flow {
      width: parent.width
      spacing: Style.space(6)

      Repeater {
        model: root.histogram
        delegate: JkChip {
          required property var modelData
          label: modelData.status + "  " + modelData.count
          tone: modelData.refused ? root.urgent : root.foreground
          fontFamily: root.fontFamily
        }
      }
    }
  }
}
