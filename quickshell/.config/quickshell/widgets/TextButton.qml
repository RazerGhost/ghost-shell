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
    opacity: enabled ? 1 : Theme.state.disabled

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: root.clicked()

    // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
    activeFocusOnTab: true
    Keys.onReturnPressed: if (enabled) root.clicked()
    Keys.onEnterPressed: if (enabled) root.clicked()
    Keys.onSpacePressed: if (enabled) root.clicked()

    // Hover highlight.
    StateLayer {
        radius: parent.radius
        color: label.color
        hovered: mouse.containsMouse
    }

    FocusRing {
        radius: root.radius
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
