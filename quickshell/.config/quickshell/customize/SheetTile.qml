import QtQuick
import qs.theme

// One setting as a tile in an editor sheet (SheetTiles lines them up): its title and a short
// note at the top, an optional control in the top-right corner (`action`: a switch), and the
// rest (`content`: a live preview and its control) below. All tiles have the same height.
Rectangle {
    id: root

    property string title
    property string subtitle
    property real weight: 1
    // Its content's width (picture cards), instead of a share by weight; 0: by weight.
    property real natural: 0
    default property alias content: body.data
    property alias action: actionSlot.data

    width: natural > 0 ? natural + Theme.spacing.m * 2 : (parent?.unit ?? 0) * weight
    height: parent?.tileHeight ?? Theme.editor.tile
    radius: Theme.radius.l
    // A shade over the sheet, glass or solid alike.
    color: Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, 0.05)

    Item {
        id: header
        x: Theme.spacing.m
        y: Theme.spacing.m
        width: parent.width - Theme.spacing.m * 2
        height: Math.max(texts.height, actionSlot.height)

        Column {
            id: texts
            anchors.left: parent.left
            anchors.right: actionSlot.left
            anchors.rightMargin: Theme.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.title
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: Font.Medium
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

        Item {
            id: actionSlot
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    // The preview and control, centered in what's left.
    Item {
        id: body
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing.m
    }
}
