import QtQuick
import qs.theme

// One setting inside a tile that holds several (SheetTile): its name on the left, its control
// on the right.
Item {
    id: root

    property string label
    default property alias control: slot.data

    width: parent?.width ?? 0
    height: Math.max(name.implicitHeight, slot.height)

    Text {
        id: name
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        elide: Text.ElideRight
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
