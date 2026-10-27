import QtQuick
import qs.theme

// Android-style slider: a thick rounded track whose filled part carries the icon.
// Click or drag to set, scroll or use the arrow keys to nudge. Like Switch, it shows `value`
// and reports changes through onMoved instead of changing `value` itself.
Rectangle {
    id: root

    property real value // 0-1
    property string icon
    property string label

    signal moved(real value)

    function move(to: real): void {
        root.moved(Math.max(0, Math.min(1, to)));
    }

    implicitHeight: Theme.slider.height
    radius: Theme.radius.full
    color: Colors.m3surfaceContainerHighest
    activeFocusOnTab: true

    Accessible.role: Accessible.Slider
    Accessible.name: label
    Accessible.onIncreaseAction: move(value + 0.05)
    Accessible.onDecreaseAction: move(value - 0.05)

    Keys.onRightPressed: move(value + 0.05)
    Keys.onUpPressed: move(value + 0.05)
    Keys.onLeftPressed: move(value - 0.05)
    Keys.onDownPressed: move(value - 0.05)

    // Filled part. Never narrower than the track is high, so the icon always fits inside.
    Rectangle {
        width: Math.max(root.height, root.width * Math.max(0, Math.min(1, root.value)))
        height: parent.height
        radius: Theme.radius.full
        color: Colors.m3primary

        Behavior on width {
            // Instant while dragging, smooth when the value changes from elsewhere.
            enabled: !drag.pressed
            NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
        }

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: (root.height - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            color: Colors.m3onPrimary
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.move(event.x / width)
        onPositionChanged: event => root.move(event.x / width)
        onWheel: event => root.move(root.value + event.angleDelta.y / 120 * 0.05)
    }
}
