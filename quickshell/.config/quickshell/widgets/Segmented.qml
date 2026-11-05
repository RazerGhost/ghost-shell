import QtQuick
import qs.theme

// A segmented control, like iOS's and macOS's: a pill with one segment per choice, the chosen
// one filled. The on-screen editors switch their sheet's tabs with it. Like Switch it doesn't
// change `current` itself: handle picked(value).
Rectangle {
    id: root

    // [{ value, label }]
    required property var options
    // What it chooses, for screen readers ("Temperature unit"); the segments are its options.
    property string label: ""
    property var current
    // Tabs (an editor's tab bar) or, by default, a choice of values (announced as radio buttons).
    property bool tabs: false

    signal picked(var value)

    // The most it may take (a narrow tile at a large shell or text size): then every segment
    // shrinks by the same share and its label shrinks to fit, instead of running past. Its own
    // width isn't read for this: a width bound to implicitWidth made a binding loop.
    property real maxWidth: Infinity
    readonly property real fit: Math.min(1, (maxWidth - Theme.spacing.xs * 2) / Math.max(implicitWidth - Theme.spacing.xs * 2, 1))

    // From the labels' text, not the segments (which take a squeezed width from this).
    width: Math.min(implicitWidth, maxWidth)
    implicitWidth: options.reduce((sum, o) => sum + natural(o.label), Theme.spacing.xs * 2)
    function natural(label: string): real {
        return metrics.advanceWidth(label) + Theme.spacing.l * 2;
    }

    FontMetrics {
        id: metrics
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        font.weight: Font.DemiBold
    }
    implicitHeight: Theme.island.height
    radius: Theme.radius.full
    color: Colors.m3surfaceContainerHighest

    Accessible.role: tabs ? Accessible.PageTabList : Accessible.Grouping
    Accessible.name: label

    Row {
        id: segments
        anchors.centerIn: parent

        Repeater {
            model: root.options

            Rectangle {
                id: segment

                required property var modelData
                readonly property bool chosen: modelData.value === root.current

                width: root.natural(modelData.label) * root.fit
                height: root.height - Theme.spacing.xs * 2
                radius: Theme.radius.full
                color: chosen ? Colors.m3primary : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

                Accessible.role: root.tabs ? Accessible.PageTab : Accessible.RadioButton
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
                    width: parent.width - Theme.spacing.s
                    horizontalAlignment: Text.AlignHCenter
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: Theme.font.small * 0.75
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
