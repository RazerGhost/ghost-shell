import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// A window asking for attention, shown by the island the way Windows flashes a taskbar
// button: app icon, title, and a click switches to it.
MouseArea {
    id: root

    required property HyprlandToplevel window

    signal activated()

    implicitHeight: Theme.tile.height + Theme.spacing.m
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()

    Accessible.role: Accessible.Button
    Accessible.name: (window?.title ?? "") + " wants your attention. Switch to it."
    Accessible.onPressAction: activated()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.l
        color: Colors.m3primaryContainer
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacing.m
        anchors.rightMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.m

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Theme.icon.launcher
            source: root.window ? Quickshell.iconPath(Windows.iconFor(root.window), "application-x-executable") : ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.icon.launcher - parent.spacing

            Text {
                width: parent.width
                text: root.window?.title ?? ""
                color: Colors.m3onPrimaryContainer
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "Wants your attention · click to switch"
                color: Colors.m3onPrimaryContainer
                opacity: 0.8
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                elide: Text.ElideRight
            }
        }
    }
}
