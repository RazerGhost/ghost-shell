import QtQuick
import qs.theme
import qs.widgets

// A round on/off button in quick settings (Android 16's small tiles): just the icon, filled with
// the accent color while on. Its name shows on hover and is what screen readers announce.
Rectangle {
    id: root

    property string icon
    property string title
    property bool active

    signal clicked()

    implicitWidth: Theme.tile.round
    implicitHeight: Theme.tile.round
    radius: Theme.radius.full
    color: active ? Colors.m3primaryContainer : Colors.m3surfaceContainerHighest

    readonly property color contentColor: active ? Colors.m3onPrimaryContainer : Colors.m3onSurface

    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.checkable: true
    Accessible.checked: active
    Accessible.onPressAction: root.clicked()

    // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Behavior on color {
        ColorAnimation { duration: Theme.anim.fast }
    }

    // Hover highlight.
    StateLayer {
        radius: parent.radius
        color: root.contentColor
        hovered: mouse.containsMouse
    }

    FocusRing {
        radius: root.radius
    }

    MaterialIcon {
        anchors.centerIn: parent
        icon: root.icon
        color: root.contentColor
    }

    // The name, while hovered or chosen with the keyboard.
    Tooltip {
        target: root
        text: root.title
        shown: mouse.containsMouse || root.activeFocus
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
