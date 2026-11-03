import QtQuick
import Quickshell
import qs.theme
import qs.widgets

// One of the island's three pills (bar/IslandWindow.qml): the workspaces on the left, the time in
// the middle, the status icons on the right. Its top row is `row`; below it, the view whose slot
// is `shown` (a menu or a hover view), into which the pill morphs: width, height and corners
// animate together. The left pill grows to the right, the right one to the left, the middle one
// both ways. Floating (the default), each is rounded all round below the top edge; attached
// (Settings' islandAttached), the middle one grows out of the top edge and the side ones out of
// the top corners (PillShape.qml).
Item {
    id: pill

    // "left", "center" or "right"
    required property string side
    // The view shown below the row ("" closed); MenuSlots compare it with their own name.
    property string shown: ""
    // Its menu is open: the keyboard goes to it (arrow keys between its controls, Escape closes).
    property bool hasFocus: false
    property real openWidth: Theme.island.panelWidth
    property alias row: row.data
    default property alias views: views.data

    readonly property bool expanded: shown !== ""
    readonly property bool hovered: content.containsMouse
    readonly property real closedWidth: row.implicitWidth + Theme.island.padding * 2
    readonly property string mode: !Theme.island.attached ? "float" : side === "center" ? "top" : side
    // Blur behind exactly the shape (ext-background-effect): the body with its round corners, and
    // the fillets (squares with the fillet's circle cut out). IslandWindow joins the three.
    readonly property Region blur: Region {
        item: content
        topLeftRadius: pill.mode === "float" ? shape.drawnRadius : 0
        topRightRadius: pill.mode === "float" ? shape.drawnRadius : 0
        bottomLeftRadius: pill.mode === "left" ? 0 : shape.drawnRadius
        bottomRightRadius: pill.mode === "right" ? 0 : shape.drawnRadius

        // The fillet into the top edge on the left ("top", "right").
        Region {
            readonly property bool used: pill.mode === "top" || pill.mode === "right"
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

        // The fillet into the top edge on the right ("top", "left").
        Region {
            readonly property bool used: pill.mode === "top" || pill.mode === "left"
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

        // The fillet into the side edge below a corner pill ("left", "right").
        Region {
            readonly property bool used: pill.mode === "left" || pill.mode === "right"
            readonly property real left: pill.mode === "left" ? pill.x : pill.x + shape.bodyX + shape.bodyWidth - shape.fillet
            x: left
            y: pill.y + shape.bodyHeight
            width: used ? shape.fillet : 0
            height: used ? shape.fillet : 0

            Region {
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: pill.mode === "left" ? pill.x : pill.x + shape.bodyX + shape.bodyWidth - shape.fillet * 2
                y: pill.y + shape.bodyHeight
                width: shape.fillet * 2
                height: shape.fillet * 2
            }
        }
    }

    signal closeRequested()

    x: side === "left" ? Theme.island.side
        : side === "right" ? parent.width - Theme.island.side - width
        : (parent.width - width) / 2 + Theme.island.offset // under the webcam
    y: Theme.island.gap
    width: shape.width
    height: shape.height

    PillShape {
        id: shape

        mode: pill.mode
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

        // The top row stays against the pill's outer side as it grows (the middle one centered).
        Row {
            id: row

            x: pill.side === "left" ? Theme.island.padding
                : pill.side === "right" ? parent.width - width - Theme.island.padding
                : (parent.width - width) / 2
            height: Theme.island.height
        }

        // The views below the row; the pill takes the height of the shown one.
        Item {
            id: views

            anchors.top: row.bottom
            x: pill.side === "left" ? 0 : pill.side === "right" ? parent.width - width : (parent.width - width) / 2
            width: Math.max(pill.closedWidth, pill.openWidth)
            implicitHeight: children.find(slot => slot.shown)?.implicitHeight ?? 0
        }
    }
}
