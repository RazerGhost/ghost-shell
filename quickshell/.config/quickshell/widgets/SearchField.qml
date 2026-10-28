import QtQuick
import qs.theme

// A rounded search field with a magnifier and a placeholder, for the island's menus (clipboard,
// emoji). Keys it doesn't use for typing (arrows, Enter) come out as keyPressed: set
// event.accepted to keep them from the field.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder
    // Something at the right end, inside the field (the clipboard's "Clear all").
    default property alias trailing: trailingSlot.data

    signal keyPressed(var event)

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: Theme.slider.height
    radius: Theme.radius.full
    color: Colors.m3surfaceContainerHighest

    MaterialIcon {
        id: searchIcon
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter
        icon: "search"
        color: Colors.m3onSurfaceVariant
    }

    TextInput {
        id: input

        anchors.left: searchIcon.right
        anchors.right: trailingSlot.left
        anchors.leftMargin: Theme.spacing.s
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        color: Colors.m3onSurface
        selectionColor: Colors.m3primary
        selectedTextColor: Colors.m3onPrimary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        clip: true

        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder

        Keys.onPressed: event => root.keyPressed(event)

        Text {
            visible: input.text === ""
            text: root.placeholder
            color: Colors.m3onSurfaceVariant
            font: input.font
        }
    }

    Item {
        id: trailingSlot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
