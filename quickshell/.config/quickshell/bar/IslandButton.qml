import QtQuick
import qs.theme
import qs.widgets

// A clickable area in the closed island (the clock, the status icons) that opens a menu.
// Highlighted on hover, and while its menu is open.
MouseArea {
    id: root

    default property alias content: row.data
    property bool active
    property string label

    signal activated()

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + Theme.spacing.m * 2
    implicitHeight: Theme.island.height - Theme.spacing.xs * 2
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.activated()
    onClicked: root.activated()

    StateLayer {
        radius: Theme.radius.full
        hovered: root.containsMouse
        active: root.active
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing.xs
    }
}
