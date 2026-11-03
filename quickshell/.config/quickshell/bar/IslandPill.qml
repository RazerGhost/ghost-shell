import QtQuick
import Quickshell
import qs.theme
import qs.widgets

// The island's shape (bar/IslandWindow.qml), under the webcam. Its top row is `row`; below it,
// the view whose slot is `shown` (a menu or a hover view), into which it morphs: width, height
// and corners animate together, growing both ways from the middle. Floating (the default) it's
// rounded all round below the top edge; attached (Settings' islandAttached) it grows out of the
// top edge (PillShape.qml).
Item {
    id: pill

    // The view shown below the row ("" closed); MenuSlots compare it with their own name.
    property string shown: ""
    // Its menu is open: the keyboard goes to it (arrow keys between its controls, Escape closes).
    property bool hasFocus: false
    property real openWidth: Theme.island.panelWidth
    property alias row: row.data
    default property alias views: views.data

    readonly property bool expanded: shown !== ""
    readonly property bool hovered: content.containsMouse
    // The row's button carries the island's padding itself, so its highlight fills the shape.
    readonly property real closedWidth: row.implicitWidth
    // Blur behind exactly the shape (ext-background-effect): the body with its round corners, and
    // the fillets (squares with the fillet's circle cut out).
    readonly property Region blur: Region {
        item: content
        topLeftRadius: Theme.island.attached ? 0 : shape.drawnRadius
        topRightRadius: Theme.island.attached ? 0 : shape.drawnRadius
        bottomLeftRadius: shape.drawnRadius
        bottomRightRadius: shape.drawnRadius

        // The fillet into the top edge on the left (attached).
        Region {
            readonly property bool used: Theme.island.attached
            x: pill.x
            y: pill.y
            width: used ? shape.fillet : 0
            height: used ? shape.fillet : 0

            Region {
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: pill.x - shape.fillet
                y: pill.y
                width: shape.fillet * 2
                height: shape.fillet * 2
            }
        }

        // The fillet into the top edge on the right (attached).
        Region {
            readonly property bool used: Theme.island.attached
            x: pill.x + shape.bodyX + shape.bodyWidth
            y: pill.y
            width: used ? shape.fillet : 0
            height: used ? shape.fillet : 0

            Region {
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: pill.x + shape.bodyX + shape.bodyWidth
                y: pill.y
                width: shape.fillet * 2
                height: shape.fillet * 2
            }
        }
    }

    signal closeRequested()

    x: (parent.width - width) / 2 + Theme.island.offset // under the webcam
    y: Theme.island.gap
    width: shape.width
    height: shape.height

    PillShape {
        id: shape

        attached: Theme.island.attached
        color: Colors.surfaceTranslucent
        edgeColor: Colors.glassEdge
        bodyWidth: pill.expanded ? Math.max(pill.closedWidth, pill.openWidth) : pill.closedWidth
        bodyHeight: Theme.island.height + (pill.expanded ? views.implicitHeight : 0)
        radius: pill.expanded ? Theme.island.openRadius : Theme.island.height / 2

        Behavior on bodyWidth {
            MorphAnimation {}
        }
        Behavior on bodyHeight {
            MorphAnimation {}
        }
        Behavior on radius {
            MorphAnimation {}
        }
    }

    // Everything inside the pill, clipped to its current size so the views are revealed as it
    // grows. A MouseArea to know whether the pointer is over the pill (hover reaches it through
    // its children too); clicks go to the buttons inside.
    MouseArea {
        id: content

        x: shape.bodyX
        width: shape.bodyWidth
        height: shape.bodyHeight
        clip: true
        focus: pill.hasFocus
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        Keys.onEscapePressed: pill.closeRequested()
        // In a menu, the arrow keys move between its controls (to the nearest one that way) and
        // Tab, with nothing chosen yet, picks the first; Enter or Space use it. Only the menu's own
        // controls: Enter on the top row's buttons would close the menu and hand the keyboard back
        // to the window.
        Keys.onPressed: event => {
            const keys = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down, Qt.Key_Tab];
            if (pill.hasFocus && keys.includes(event.key) && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
                event.accepted = navigation.move(event.key);
        }

        ArrowNavigation {
            id: navigation
            area: views
        }

        // The top row stays centered as it grows.
        Row {
            id: row

            x: (parent.width - width) / 2
            height: Theme.island.height
        }

        // The views below the row; the pill takes the height of the shown one.
        Item {
            id: views

            anchors.top: row.bottom
            x: (parent.width - width) / 2
            width: Math.max(pill.closedWidth, pill.openWidth)
            implicitHeight: children.find(slot => slot.shown)?.implicitHeight ?? 0
        }
    }
}
