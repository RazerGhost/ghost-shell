import QtQuick
import qs.theme

// Material 3 switch. Doesn't change `checked` itself: handle onToggled and update the
// value it's bound to, so the switch always shows the real state (e.g. Wi-Fi turning on).
Rectangle {
    id: root

    property bool checked
    property string label

    signal toggled()

    implicitWidth: Theme.toggle.width
    implicitHeight: Theme.toggle.height
    radius: Theme.radius.full
    color: checked ? Colors.m3primary : Colors.m3surfaceContainerHighest
    border.width: checked ? 0 : Theme.toggle.border
    border.color: Colors.m3outlineVariant

    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checkable: true
    Accessible.checked: checked
    Accessible.onToggleAction: root.toggled()
    Accessible.onPressAction: root.toggled()

    // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
    activeFocusOnTab: true
    Keys.onReturnPressed: root.toggled()
    Keys.onEnterPressed: root.toggled()
    Keys.onSpacePressed: root.toggled()

    Behavior on color {
        ColorAnimation { duration: Theme.anim.fast }
    }

    FocusRing {
        radius: root.radius
    }

    // The thumb grows and slides to the right when on, and grows more while held.
    Rectangle {
        readonly property real inset: (root.height - width) / 2

        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - inset : inset
        width: press.pressed ? Theme.toggle.thumbPressed : root.checked ? Theme.toggle.thumbOn : Theme.toggle.thumbOff
        height: width
        radius: Theme.radius.full
        color: root.checked ? Colors.m3onPrimary : Colors.m3onSurfaceVariant

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
        Behavior on width {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    MouseArea {
        id: press
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    StateLayer {
        radius: root.radius
        color: root.checked ? Colors.m3onPrimary : Colors.m3onSurface
        hovered: press.containsMouse
    }
}
