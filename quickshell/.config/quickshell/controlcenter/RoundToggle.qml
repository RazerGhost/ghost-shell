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

    Behavior on color {
        ColorAnimation { duration: Theme.anim.fast }
    }

    // Hover highlight.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.contentColor
        opacity: mouse.containsMouse ? 0.08 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fast }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        icon: root.icon
        color: root.contentColor
    }

    // The name, under the button while hovered.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: Theme.spacing.xs
        z: 1
        width: name.implicitWidth + Theme.spacing.m * 2
        height: name.implicitHeight + Theme.spacing.xs * 2
        radius: Theme.radius.full
        color: Colors.m3surfaceContainerHighest
        opacity: mouse.containsMouse ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fast }
        }

        Text {
            id: name
            anchors.centerIn: parent
            text: root.title
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
