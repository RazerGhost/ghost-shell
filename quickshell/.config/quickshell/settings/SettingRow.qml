import QtQuick
import qs.theme

// One setting: its name and a short explanation on the left, the control (a Switch, a
// Stepper, ...) on the right. The control goes inside the row as its child.
Item {
    id: root

    property string title
    property string subtitle
    default property alias control: slot.data

    width: parent?.width ?? 0
    implicitHeight: Math.max(Theme.settings.rowHeight, texts.implicitHeight + Theme.spacing.m * 2)
    // A disabled row (a schedule's times while there's no schedule) is dimmed.
    opacity: enabled ? 1 : 0.5

    Column {
        id: texts

        anchors.left: parent.left
        anchors.right: slot.left
        anchors.leftMargin: Theme.spacing.l
        anchors.rightMargin: Theme.spacing.l
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot

        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.l
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
