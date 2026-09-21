import QtQuick
import qs.Commons
import "Model.js" as Model

// Activity instrument: calls per time bucket across a window, answers stacked
// under refusals. It draws counts of ledger rows and nothing else — a taller
// bar is more calls, never more assurance — and it says "recall" wherever a
// caller lets it label itself.
Item {
  id: root

  property var series: ({ buckets: [], max: 0, startMs: 0, endMs: 0, bucketMs: 0 })
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  property string emptyText: "no calls in this window"
  property bool showLabels: true
  property int hoverIndex: -1

  readonly property var buckets: series && series.buckets ? series.buckets : []
  readonly property var hovered: hoverIndex >= 0 && hoverIndex < buckets.length ? buckets[hoverIndex] : null
  readonly property real gutterBottom: showLabels ? Style.space(18) : 0
  readonly property real gutterLeft: showLabels ? Style.space(26) : 0

  onSeriesChanged: canvas.requestPaint()
  onHoverIndexChanged: canvas.requestPaint()
  onForegroundChanged: canvas.requestPaint()
  onAccentChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var w = width
      var h = height
      var list = root.buckets
      var n = list.length
      var max = root.series && root.series.max ? root.series.max : 0
      var fontPx = Style.font.caption
      ctx.font = fontPx + "px " + root.fontFamily

      var left = root.gutterLeft
      var top = Style.space(4)
      var plotW = Math.max(1, w - left - Style.space(2))
      var plotH = Math.max(1, h - top - root.gutterBottom)

      // grid
      var grid = Util.alpha(root.foreground, 0.10)
      var faint = Util.alpha(root.foreground, 0.46)
      ctx.strokeStyle = grid
      ctx.lineWidth = 1
      var levels = [0, 0.5, 1]
      for (var g = 0; g < levels.length; g++) {
        var gy = Math.round(top + plotH - levels[g] * plotH) + 0.5
        ctx.beginPath()
        ctx.moveTo(left, gy)
        ctx.lineTo(left + plotW, gy)
        ctx.stroke()
        if (root.showLabels && max > 0 && levels[g] > 0) {
          var lbl = String(Math.round(max * levels[g]))
          ctx.fillStyle = faint
          ctx.fillText(lbl, left - ctx.measureText(lbl).width - Style.space(6), gy + fontPx * 0.35)
        }
      }

      if (n === 0 || max === 0) {
        ctx.fillStyle = faint
        var et = root.emptyText
        ctx.fillText(et, left + (plotW - ctx.measureText(et).width) / 2, top + plotH / 2 + fontPx * 0.35)
      } else {
        var slot = plotW / n
        var barW = Math.max(1, Math.floor(slot * 0.68))
        var inset = (slot - barW) / 2
        for (var i = 0; i < n; i++) {
          var b = list[i]
          if (!b || b.total === 0) continue
          var x = Math.round(left + i * slot + inset)
          var hot = i === root.hoverIndex
          var aH = Math.round(b.answered / max * plotH)
          var rH = Math.round(b.refused / max * plotH)
          if (aH > 0) {
            ctx.fillStyle = Util.alpha(root.accent, hot ? 1.0 : 0.72)
            ctx.fillRect(x, top + plotH - aH, barW, aH)
          }
          if (rH > 0) {
            ctx.fillStyle = Util.alpha(root.urgent, hot ? 1.0 : 0.85)
            ctx.fillRect(x, top + plotH - aH - rH, barW, rH)
          }
        }
      }

      if (root.showLabels && root.series && root.series.startMs > 0) {
        ctx.fillStyle = faint
        var y = h - Style.space(4)
        var startText = Model.dayClockText(root.series.startMs)
        var midText = Model.dayClockText(root.series.startMs + (root.series.endMs - root.series.startMs) / 2)
        var endText = "now"
        ctx.fillText(startText, left, y)
        ctx.fillText(midText, left + (plotW - ctx.measureText(midText).width) / 2, y)
        ctx.fillText(endText, left + plotW - ctx.measureText(endText).width, y)
      }

      if (root.hovered) {
        var hb = root.hovered
        var read = Model.dayClockText(hb.startMs) + " – " + Model.clockText(hb.endMs)
          + "   " + Model.countText(hb.answered, "answer", "answers")
          + (hb.refused > 0 ? "   " + hb.refused + " refused" : "")
        ctx.fillStyle = root.foreground
        var rw = ctx.measureText(read).width
        ctx.fillText(read, Math.max(left, left + plotW - rw), top + fontPx)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onPositionChanged: function(mouse) {
      var n = root.buckets.length
      if (n === 0) { root.hoverIndex = -1; return }
      var plotW = Math.max(1, root.width - root.gutterLeft - Style.space(2))
      var rel = (mouse.x - root.gutterLeft) / plotW
      root.hoverIndex = rel < 0 || rel > 1 ? -1 : Math.min(n - 1, Math.floor(rel * n))
    }
    onExited: root.hoverIndex = -1
  }
}
