import QtQuick
import qs.theme
import qs.widgets

// The closed island's clickable middle: a click opens its menu, a right-click another
// (`secondaryActivated`, quick settings). It fills the closed island, so hover highlights the
// whole shape, not just the time. Not while a menu is open (`active`): the time alone lit up at
// the top of the menu looked odd (user's find).
MouseArea {
    id: root

    default property alias content: row.data
    property bool active
    property string label

    // What a right-click does, for screen readers ("" for nothing).
    property string secondaryLabel
    // More for screen readers (what the content inside says), read before the right-click.
    property string details

    signal activated()
    signal secondaryActivated()

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + (Theme.island.padding + Theme.spacing.m) * 2
    implicitHeight: Theme.island.height
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.description: [details, secondaryLabel ? "Right-click: " + secondaryLabel : ""]
        .filter(text => text !== "").join(". ")
    Accessible.onPressAction: root.activated()
    onClicked: mouse => mouse.button === Qt.RightButton ? root.secondaryActivated() : root.activated()

    StateLayer {
        radius: height / 2
        // Attached, the island's top runs into the screen's edge: square there too.
        topLeftRadius: Theme.island.attached ? 0 : radius
        topRightRadius: Theme.island.attached ? 0 : radius
        hovered: root.containsMouse && !root.active
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing.xs
    }
}
