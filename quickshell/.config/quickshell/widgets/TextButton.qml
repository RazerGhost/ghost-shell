import QtQuick
import qs.theme

// Material 3 text button; `filled` makes it the accent-colored main action.
Rectangle {
    id: root

    property alias text: label.text
    property bool filled

    signal clicked()

    implicitWidth: label.implicitWidth + Theme.spacing.l * 2
    implicitHeight: Theme.island.height
    radius: Theme.radius.full
    color: filled ? Colors.m3primary : "transparent"
    opacity: enabled ? 1 : 0.4

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: root.clicked()

    // Hover highlight.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: label.color
        opacity: mouse.containsMouse ? 0.12 : 0
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.filled ? Colors.m3onPrimary : Colors.m3primary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
