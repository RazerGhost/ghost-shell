import QtQuick
import QtQuick.Shapes
import qs.theme

// A ring that fills clockwise from the top with `value` (0-1) over a faint track: the battery
// and timer widgets. Content (an icon, a number) goes in its middle.
Item {
    id: root

    property real value: 0
    property color color: Colors.m3primary
    property color track: Colors.tint
    readonly property real lineWidth: Theme.desktop.ringWidth

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
                startAngle: -90
                sweepAngle: 360
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
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(root.value, 1))
                Behavior on sweepAngle { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }
            }
        }
    }
}
