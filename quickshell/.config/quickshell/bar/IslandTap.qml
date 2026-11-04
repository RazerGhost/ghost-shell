import QtQuick
import qs.theme
import qs.widgets

// Makes one of the closed island's small things clickable (an alert, the workspace dots' and the
// status icons' neighbours when it widens): fills its parent and a little around it, says what a
// click does in a tooltip and to screen readers, and takes the click from the island's own button
// (IslandButton) underneath. The wheel and other buttons still reach the island.
MouseArea {
    id: root

    // What a click does ("Stop the recording").
    property string label

    signal tapped()

    anchors.fill: parent
    anchors.margins: -Theme.spacing.xs
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.tapped()

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.tapped()

    Tooltip {
        target: root
        text: root.label
        shown: root.containsMouse
    }
}
