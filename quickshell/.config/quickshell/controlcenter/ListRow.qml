import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.widgets

// A row in the Wi-Fi, Bluetooth and minimized-window lists: icon, name, state, and an optional
// trailing icon. `icon` is a Material Symbol; `appIcon` (an icon theme name) replaces it with an
// app's own icon. `highlighted` (the connected network or device) draws it in the accent color.
MouseArea {
    id: root

    property string icon
    property string appIcon
    property string title
    property string subtitle
    property string trailingIcon
    property bool highlighted

    readonly property color contentColor: highlighted ? Colors.m3primary : Colors.m3onSurface

    implicitHeight: Theme.list.rowHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Accessible.role: Accessible.ListItem
    Accessible.name: title + ", " + subtitle
    signal activated()

    Accessible.onPressAction: root.activated()
    onClicked: root.activated()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.m
        color: Colors.m3onSurface
        opacity: root.containsMouse ? 0.08 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fast }
        }
    }

    Item {
        id: leading
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.icon.normal
        height: width

        // WifiIcon: a weak Wi-Fi signal keeps its unlit arcs visible (dimmed); other symbols
        // are drawn as is.
        WifiIcon {
            anchors.centerIn: parent
            visible: root.appIcon === ""
            icon: root.icon
            color: root.contentColor
        }

        IconImage {
            anchors.fill: parent
            visible: root.appIcon !== ""
            source: visible ? Quickshell.iconPath(root.appIcon, "application-x-executable") : ""
        }
    }

    Column {
        anchors.left: leading.right
        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.leftMargin: Theme.spacing.m
        anchors.rightMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            color: root.contentColor
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: root.highlighted ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    MaterialIcon {
        id: trailing
        visible: root.trailingIcon !== ""
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter
        icon: root.trailingIcon
        color: Colors.m3onSurfaceVariant
        font.pixelSize: Theme.icon.small
    }
}
