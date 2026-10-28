import QtQuick
import qs.theme
import qs.widgets

// Quick settings tile, like Android's: icon, title and state. Filled with the accent color
// while active. Tiles with a page of their own (Wi-Fi, Bluetooth) show a chevron.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active
    property bool hasPage

    signal clicked()

    implicitHeight: Theme.tile.height
    radius: Theme.radius.l
    color: active ? Colors.m3primaryContainer : Colors.m3surfaceContainerHighest

    readonly property color contentColor: active ? Colors.m3onPrimaryContainer : Colors.m3onSurface

    Accessible.role: Accessible.Button
    Accessible.name: title + ", " + subtitle
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

    // WifiIcon: a weak Wi-Fi signal keeps its unlit arcs visible (dimmed); other symbols
    // are drawn as is.
    WifiIcon {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.l
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        color: root.contentColor
    }

    Column {
        anchors.left: glyph.right
        anchors.right: chevron.visible ? chevron.left : parent.right
        anchors.leftMargin: Theme.spacing.m
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            color: root.contentColor
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: root.contentColor
            opacity: 0.8
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    MaterialIcon {
        id: chevron
        visible: root.hasPage
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        icon: "chevron_right"
        color: root.contentColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
