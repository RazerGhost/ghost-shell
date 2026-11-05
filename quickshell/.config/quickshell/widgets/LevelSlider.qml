import QtQuick
import qs.theme

// Android-style slider: a thick rounded track whose filled part carries the icon.
// Click or drag to set, scroll or use Left and Right to nudge (Up and Down move on to the next
// control in the island's menus). Like Switch, it shows `value`
// and reports changes through onMoved instead of changing `value` itself.
Rectangle {
    id: root

    property real value // 0-1
    property string icon
    property string label
    // An optional button inside the track's right end (the volume's output chooser), like
    // Android's: its icon and screen reader name; none while `actionIcon` is empty.
    property string actionIcon
    property string actionLabel

    signal moved(real value)
    signal actionClicked()

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
    Keys.onLeftPressed: move(value - 0.05)

    FocusRing {
        radius: root.radius
    }

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

    // Over the drag area, so a click on it doesn't set the level. Its color follows what's under
    // it: the filled part once the level reaches it, the empty track before.
    IconButton {
        visible: root.actionIcon !== ""
        anchors.right: parent.right
        anchors.rightMargin: (root.height - height) / 2
        anchors.verticalCenter: parent.verticalCenter
        icon: root.actionIcon
        label: root.actionLabel
        color: root.value * root.width >= root.width - root.height / 2 ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
        onClicked: root.actionClicked()
    }
}
