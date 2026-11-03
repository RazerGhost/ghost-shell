import QtQuick
import qs.theme
import qs.widgets

// The closed island's clickable middle: a click opens its menu, a right-click another
// (`secondaryActivated`, quick settings). Highlighted on hover, and while a menu is open.
MouseArea {
    id: root

    default property alias content: row.data
    property bool active
    property string label

    // What a right-click does, for screen readers ("" for nothing).
    property string secondaryLabel

    signal activated()
    signal secondaryActivated()

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + Theme.spacing.m * 2
    implicitHeight: Theme.island.height - Theme.spacing.xs * 2
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.description: secondaryLabel ? "Right-click: " + secondaryLabel : ""
    Accessible.onPressAction: root.activated()
    onClicked: mouse => mouse.button === Qt.RightButton ? root.secondaryActivated() : root.activated()

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
