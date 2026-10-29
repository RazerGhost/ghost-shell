import QtQuick
import qs.theme

// A segmented control, like iOS's and macOS's: a pill with one segment per choice, the chosen
// one filled. The on-screen editors switch their sheet's tabs with it. Like Switch it doesn't
// change `current` itself: handle picked(value).
Rectangle {
    id: root

    // [{ value, label }]
    required property var options
    property var current

    signal picked(var value)

    implicitWidth: segments.implicitWidth + Theme.spacing.xs * 2
    implicitHeight: Theme.island.height
    radius: Theme.radius.full
    color: Colors.m3surfaceContainerHighest

    Accessible.role: Accessible.PageTabList

    Row {
        id: segments
        anchors.centerIn: parent

        Repeater {
            model: root.options

            Rectangle {
                id: segment

                required property var modelData
                readonly property bool chosen: modelData.value === root.current

                width: label.implicitWidth + Theme.spacing.l * 2
                height: root.height - Theme.spacing.xs * 2
                radius: Theme.radius.full
                color: chosen ? Colors.m3primary : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                Accessible.checked: chosen
                Accessible.onPressAction: root.picked(modelData.value)

                // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
                activeFocusOnTab: true
                Keys.onReturnPressed: root.picked(modelData.value)
                Keys.onEnterPressed: root.picked(modelData.value)
                Keys.onSpacePressed: root.picked(modelData.value)

                StateLayer {
                    radius: parent.radius
                    color: label.color
                    hovered: mouse.containsMouse && !segment.chosen
                }

                FocusRing {
                    radius: segment.radius
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: segment.chosen ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(segment.modelData.value)
                }
            }
        }
    }
}
