import QtQuick
import QtQuick.Shapes
import qs.theme

// A ring that fills clockwise from the top with `value` (0-1) over a faint track: the battery
// and timer widgets. Content (an icon, a number) goes in its middle. With `span` under 360 it's a
// gauge open at the bottom, filling from its left end (the lock screen's battery, like iOS's).
Item {
    id: root

    property real value: 0
    property color color: Colors.m3primary
    property color track: Colors.tint
    property real lineWidth: Theme.desktop.ringWidth
    // Degrees of the circle drawn; the gap is at the bottom.
    property real span: 360
    readonly property real start: span >= 360 ? -90 : 90 + (360 - span) / 2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.track
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: radiusX
                startAngle: root.start
                sweepAngle: root.span
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2
                radiusY: radiusX
                startAngle: root.start
                sweepAngle: root.span * Math.max(0, Math.min(root.value, 1))
                Behavior on sweepAngle { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }
            }
        }
    }
}
