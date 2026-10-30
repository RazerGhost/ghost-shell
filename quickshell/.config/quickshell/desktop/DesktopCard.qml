import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "DesktopWidgets.js" as DesktopWidgets

// One desktop widget at its saved place (Settings' desktopWidgets, as fractions of the screen).
// It fades and grows in when shown, and lifts a little under the pointer. Resting the pointer
// on it (or the desktop editor being open) shows a handle in its top-right corner; drag that to
// move it, and a drop near the screen's edges or another widget lines up with them. Only the
// handle: the media widget's buttons keep their clicks.
Item {
    id: root

    // Its key in desktopWidgets ("clock", "weather", "media").
    required property string name
    // On (its setting, and for media something to play); it stays visible while fading out.
    property bool shown: true
    default property alias content: body.data

    readonly property var spot: DesktopWidgets.place(Settings.values.desktopWidgets, name)

    // How far the handle has been dragged; follows the drag while it lasts, and the place is
    // saved when it ends. Kept here, not read from the handler at the end: by then its
    // translation is already back to nothing (NOTES).
    property point dragged: Qt.point(0, 0)
    property bool moving: false

    x: spot.x * parent.width + (moving ? dragged.x : 0)
    y: spot.y * parent.height + (moving ? dragged.y : 0)
    width: body.childrenRect.width
    height: body.childrenRect.height

    visible: opacity > 0
    opacity: shown ? 1 : 0
    scale: !shown ? 0.92 : hover.hovered && !drag.active ? 1.02 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }

    Item {
        id: body
        anchors.fill: parent
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: handle
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacing.s
        width: Theme.icon.normal + Theme.spacing.s
        height: width
        radius: width / 2
        color: Colors.m3surfaceContainerHighest
        opacity: hover.hovered || drag.active || Editing.desktop ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

        Accessible.role: Accessible.Button
        Accessible.name: "Move the " + root.name + " widget"

        MaterialIcon {
            anchors.centerIn: parent
            icon: "drag_pan"
            color: Colors.m3onSurfaceVariant
            font.pixelSize: Theme.icon.small
        }

        HoverHandler {
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        DragHandler {
            id: drag
            target: null
            // The pointer's move on the screen, in the widgets' own units: while the desktop
            // editor shows them scaled into its card, a move of 10 px is 10 / scale of theirs, so
            // the handle stays under the pointer.
            onCentroidChanged: {
                if (!active)
                    return;
                const scale = root.parent?.scale ?? 1;
                root.dragged = Qt.point((centroid.scenePosition.x - centroid.scenePressPosition.x) / scale,
                                        (centroid.scenePosition.y - centroid.scenePressPosition.y) / scale);
            }
            onActiveChanged: {
                if (active) {
                    root.dragged = Qt.point(0, 0);
                    root.moving = true;
                    return;
                }
                const area = root.parent;
                // The other widgets showing, to line up with.
                const others = Array.from(area.children)
                    .filter(c => c !== root && c.name !== undefined && c.visible)
                    .map(c => ({ x: c.x, y: c.y, w: c.width, h: c.height }));
                const at = DesktopWidgets.snapped(root.spot.x * area.width + root.dragged.x,
                                                  root.spot.y * area.height + root.dragged.y,
                                                  root.width, root.height, area.width, area.height, others,
                                                  Theme.desktop.margin, Theme.desktop.gap, Theme.desktop.reach);
                const place = DesktopWidgets.dropped(at.x, at.y, root.width, root.height, area.width, area.height);
                Settings.values.desktopWidgets = DesktopWidgets.withPlace(Settings.values.desktopWidgets, root.name, place);
                root.moving = false;
            }
        }
    }
}
