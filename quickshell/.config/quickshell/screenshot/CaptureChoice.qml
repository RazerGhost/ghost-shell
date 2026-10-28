import QtQuick
import qs.theme
import qs.widgets

// One choice in the screenshot tool's bar (Screenshot.qml): an icon and a label, filled while
// selected. Its own file: as an inline component in Screenshot.qml, Quickshell reported
// "Segment is not a type".
MouseArea {
    id: segment

    property string icon
    property string label
    property bool selected
    signal picked()

    width: segmentRow.implicitWidth + Theme.spacing.l * 2
    height: Theme.island.height
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: picked()

    Accessible.role: Accessible.RadioButton
    Accessible.name: label
    Accessible.checked: selected
    Accessible.onPressAction: picked()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.full
        color: segment.selected ? Colors.m3primaryContainer : Colors.m3onSurface
        opacity: segment.selected ? 1 : segment.containsMouse ? Theme.state.hover : 0
    }

    Row {
        id: segmentRow
        anchors.centerIn: parent
        spacing: Theme.spacing.s

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: segment.icon
            color: segment.selected ? Colors.m3onPrimaryContainer : Colors.m3onSurface
            font.pixelSize: Theme.icon.small
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: segment.label
            color: segment.selected ? Colors.m3onPrimaryContainer : Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }
}
