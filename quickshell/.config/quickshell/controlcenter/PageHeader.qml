import QtQuick
import qs.theme
import qs.widgets

// Header of a quick settings sub-page: back arrow, title, and an on/off switch (hasSwitch).
Item {
    id: root

    property string title
    property bool checked
    property bool hasSwitch: true

    signal back()
    signal toggled()

    implicitHeight: Theme.slider.height

    IconButton {
        id: backButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        icon: "arrow_back"
        label: "Back"
        onClicked: root.back()
    }

    Text {
        anchors.left: backButton.right
        anchors.leftMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.large
        font.weight: Font.DemiBold
    }

    Switch {
        visible: root.hasSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        label: root.title
        onToggled: root.toggled()
    }
}
