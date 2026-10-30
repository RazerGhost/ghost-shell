import QtQuick
import qs.theme
import qs.widgets

// A setting picked by sight, like macOS's Appearance thumbnails or the iOS lock screen
// gallery: a row of small pictures with a name under each; the current one has an accent
// outline. `art` draws a card's picture; it's given the option as `option` on its parent
// (`parent.option`). The on-screen editors' (customize/) tiles hold them.
Column {
    id: root

    property string title
    property string subtitle
    // [{ value, label }]
    required property var options
    property var current
    // Several chosen at once (on/off cards: the desktop widgets) instead of `current`; picked()
    // then means "toggle this one".
    property var chosenValues: null
    property Component art
    // One row that scrolls sideways (many choices: the wallpapers), instead of wrapping rows.
    property bool scrolls: false
    // A scrolling row fades out at its end into this (the color behind it), so it reads as
    // going on; transparent: no fade.
    property color fadeColor: "transparent"

    signal picked(var value)

    property real cardWidth: Theme.settings.card
    property real cardHeight: Math.round(cardWidth * 10 / 16)

    // As wide as its cards in one row; a scrolling row takes the whole row of its sheet (the
    // tile, less the side margins).
    width: scrolls ? (parent?.width ?? 0) - Theme.spacing.l * 2
                   : options.length * cardWidth + Math.max(options.length - 1, 0) * Theme.spacing.m
    spacing: Theme.spacing.s

    Column {
        width: parent.width
        visible: root.title !== ""
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            // A line kept even without a subtitle, so cards and settings beside them line up.
            text: root.subtitle || " "
            maximumLineCount: 1
            elide: Text.ElideRight
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }

    Item {
        id: area
        width: parent.width
        height: root.scrolls ? row.height : flow.height

        Flow {
            id: flow
            width: parent.width
            visible: !root.scrolls
            spacing: Theme.spacing.m

            Repeater {
                model: root.scrolls ? [] : root.options
                delegate: cardComponent
            }
        }

        ListView {
            id: row
            width: parent.width
            height: contentItem.childrenRect.height
            visible: root.scrolls
            orientation: ListView.Horizontal
            spacing: Theme.spacing.m
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.scrolls ? root.options : []
            delegate: cardComponent
        }

        Rectangle {
            anchors.right: row.right
            width: Theme.spacing.l * 3
            height: row.height
            visible: root.scrolls && root.fadeColor.a > 0 && !row.atXEnd
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: root.fadeColor }
            }
        }
    }

    Component {
        id: cardComponent

        Column {
            id: card

            required property var modelData
            required property int index
            readonly property bool chosen: root.chosenValues ? root.chosenValues.includes(modelData.value)
                                                                 : modelData.value === root.current

            spacing: Theme.spacing.xs

            Accessible.role: root.chosenValues ? Accessible.CheckBox : Accessible.RadioButton
            Accessible.name: modelData.label
            Accessible.checked: chosen
            Accessible.onPressAction: root.picked(modelData.value)

            // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
            activeFocusOnTab: true
            // Tab (or the arrow keys) to a card further along the row: the row scrolls to it.
            onActiveFocusChanged: {
                if (activeFocus && root.scrolls)
                    row.positionViewAtIndex(index, ListView.Contain);
            }
            Keys.onReturnPressed: root.picked(modelData.value)
            Keys.onEnterPressed: root.picked(modelData.value)
            Keys.onSpacePressed: root.picked(modelData.value)

            Rectangle {
                id: frame
                width: root.cardWidth
                height: root.cardHeight
                radius: Theme.radius.m
                color: Colors.m3surfaceContainerHigh
                clip: true

                Loader {
                    readonly property var option: card.modelData
                    anchors.fill: parent
                    sourceComponent: root.art
                }

                StateLayer {
                    radius: frame.radius
                    color: Colors.m3onSurface
                    hovered: mouse.containsMouse
                }

                // The chosen one's outline, over the picture.
                Rectangle {
                    anchors.fill: parent
                    radius: frame.radius
                    color: "transparent"
                    border.width: card.chosen ? Theme.outline.strong : 0
                    border.color: Colors.m3primary
                }

                FocusRing {
                    control: card
                    radius: frame.radius
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(card.modelData.value)
                }
            }

            Text {
                width: frame.width
                text: card.modelData.label
                horizontalAlignment: Text.AlignHCenter
                color: card.chosen ? Colors.m3primary : Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.weight: card.chosen ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
        }
    }
}
