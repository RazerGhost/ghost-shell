import QtQuick
import qs.services
import qs.theme
import "DisplayModes.js" as DisplayModes

// Where the screens sit against each other (Settings -> Display, with several): each screen a
// card at its size on the desktop, dragged into place; let go, it lines up beside the nearest
// screen (DisplayModes.arranged) and the arrangement is saved for this set of screens
// (screenLayouts, by their keys), so the desk at home and a projector at work keep their own.
// The pointer crosses from one screen to the next where their edges meet.
Item {
    id: root

    property var monitors: [] // `hyprctl monitors -j`'s entries
    property var nameOf: output => output // the page's name for a screen

    // The screens as rects in Hyprland's layout pixels, the main one first.
    readonly property var rects: {
        const list = monitors.map(m => Object.assign({ key: DisplayModes.key(m, monitors), name: m.name, x: m.x, y: m.y }, DisplayModes.logicalSize(m)));
        const main = list.find(r => r.name === Screens.main?.name);
        return main ? [main, ...list.filter(r => r !== main)] : list;
    }
    readonly property real minX: Math.min(...rects.map(r => r.x), 0)
    readonly property real minY: Math.min(...rects.map(r => r.y), 0)
    readonly property real spanW: Math.max(...rects.map(r => r.x + r.w), 1) - minX
    readonly property real spanH: Math.max(...rects.map(r => r.y + r.h), 1) - minY
    // Fits the drawing, with room around it to drag into.
    readonly property real k: Math.min((width - Theme.spacing.l * 4) / spanW, (height - Theme.spacing.l * 2) / spanH)
    readonly property real ox: (width - spanW * k) / 2 - minX * k
    readonly property real oy: (height - spanH * k) / 2 - minY * k

    signal arranged(var positions)

    implicitHeight: Theme.px(220)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.m
        color: Colors.m3surfaceContainer
    }

    Repeater {
        model: root.rects

        Rectangle {
            id: card

            required property var modelData
            readonly property bool main: modelData.name === Screens.main?.name

            x: root.ox + modelData.x * root.k
            y: root.oy + modelData.y * root.k
            width: modelData.w * root.k
            height: modelData.h * root.k
            radius: Theme.radius.s
            color: drag.drag.active ? Colors.m3primaryContainer : Colors.m3surfaceContainerHighest
            border.width: Theme.outline.normal
            border.color: main ? Colors.m3primary : Colors.m3outlineVariant
            z: drag.drag.active ? 1 : 0

            Accessible.role: Accessible.Graphic
            Accessible.name: root.nameOf(modelData.name) + (main ? ", main screen" : "")

            Column {
                anchors.centerIn: parent
                width: parent.width - Theme.spacing.s * 2

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.nameOf(card.modelData.name)
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: card.main
                    horizontalAlignment: Text.AlignHCenter
                    text: "Main"
                    color: Colors.m3primary
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }
            }

            MouseArea {
                id: drag
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                drag.target: card
                onReleased: {
                    if (!drag.drag.active)
                        return;
                    // Back to layout pixels, lined up beside the nearest screen.
                    const x = (card.x - root.ox) / root.k;
                    const y = (card.y - root.oy) / root.k;
                    // Lined up with an edge or the middle within 16 px as drawn.
                    root.arranged(DisplayModes.arranged(root.rects, card.modelData.key, x, y, Theme.px(16) / root.k));
                    // The binding comes back with the new places (or the old ones).
                    card.x = Qt.binding(() => root.ox + card.modelData.x * root.k);
                    card.y = Qt.binding(() => root.oy + card.modelData.y * root.k);
                }
            }
        }
    }
}
