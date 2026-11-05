import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "DesktopWidgets.js" as DesktopWidgets

// One desktop widget at its saved place (Settings' desktopWidgets, as fractions of the screen).
// It fades and grows in when shown, and lifts a little under the pointer. While the desktop
// editor is open a handle shows in its top-right corner (only then, so the widgets look clean
// day to day); drag that to move it, and a drop near the screen's edges or another widget lines
// up with them, or with the grid while it's on (Settings' desktopGrid). Only the
// handle: the media widget's buttons keep their clicks. On the lock screen (the stage's
// `locked`) there's no handle, and only the media widget takes clicks.
Item {
    id: root

    // Its key in desktopWidgets (DesktopWidgets.js's `kinds`: "clock", "weather", "media", ...).
    required property string name
    // On (its setting, and for media something to play); it stays visible while fading out.
    property bool wanted: true
    // On this stage's screen (DesktopWidgets.screenOf: the screen saved with its place, else the
    // main one); a stage without a screen (the editor's gallery) shows every widget.
    readonly property bool here: (parent?.screenName ?? "") === ""
        || DesktopWidgets.screenOf(Settings.values.desktopWidgets, name, Quickshell.screens.map(s => s.name),
                                   Screens.main?.name ?? "") === parent.screenName
    readonly property bool shown: wanted && here
    default property alias content: body.data
    // The widget inside (a WidgetSurface).
    readonly property Item widget: body.children[0] ?? null
    readonly property bool locked: parent?.locked === true

    readonly property var spot: DesktopWidgets.place(Settings.values.desktopWidgets, name)
    // Where that is at the shell's size: places zoom with the widgets, a group of them together
    // (the stage's `arranged`, DesktopWidgets.arrange); on its own while it isn't shown.
    readonly property point at: {
        const p = parent?.arranged?.[name]
            ?? DesktopWidgets.shown(spot, width, height, parent?.width ?? 0, parent?.height ?? 0, Theme.desktop.zoom);
        return Qt.point(p.x, p.y);
    }

    // How far the handle has been dragged; follows the drag while it lasts, and the place is
    // saved when it ends. Kept here, not read from the handler at the end: by then its
    // translation is already back to nothing (NOTES).
    property point dragged: Qt.point(0, 0)
    property bool moving: false
    // A drop being saved: no glide while the drag is put away and the place written (both at
    // once would count the drag twice for a moment).
    property bool settling: false

    x: at.x + (moving ? dragged.x : 0)
    y: at.y + (moving ? dragged.y : 0)
    // A new place (a widget layout, "Put them back", a drop lining up) is glided to; the drag
    // itself follows the pointer.
    Behavior on x { enabled: !root.moving && !root.settling; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
    Behavior on y { enabled: !root.moving && !root.settling; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
    width: body.childrenRect.width
    height: body.childrenRect.height

    visible: opacity > 0
    enabled: !locked || name === "media"
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

    // Outlined while the desktop editor's keyboard is on this widget (Editing.widget).
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Theme.spacing.xs
        visible: Editing.widget === root.name && !root.locked
        radius: Theme.desktop.radius + Theme.spacing.xs
        color: "transparent"
        border.width: Theme.focus.width / (root.parent?.scale ?? 1)
        border.color: Colors.m3primary
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
        visible: !root.locked && opacity > 0
        opacity: Editing.desktop || drag.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

        // A grip to drag (no press action: dragging is what it does).
        Accessible.role: Accessible.Grip
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
                const x = root.at.x + root.dragged.x;
                const y = root.at.y + root.dragged.y;
                const at = Settings.values.desktopGrid
                    ? DesktopWidgets.gridSnapped(x, y, root.width, root.height, area.width, area.height,
                                                 Theme.px(DesktopWidgets.gridSize(Settings.values.desktopGridSize)))
                    : DesktopWidgets.snapped(x, y, root.width, root.height, area.width, area.height, others,
                                             Theme.desktop.margin, Theme.desktop.gap, Theme.desktop.reach);
                // Let go past this screen's edge onto another (its middle there): it moves to that
                // screen, placed where it was let go (not while the editor shows it in its card).
                const here = area.screenName ?? "";
                const own = Display.monitors.find(m => m.name === here);
                const middle = own && area.scale === 1
                    ? DesktopWidgets.screenAt(Display.monitors, own.x + x + root.width / 2, own.y + y + root.height / 2) : null;
                const moved = middle !== null && middle.name !== here;
                const target = moved ? middle : { name: here, w: area.width, h: area.height };
                const local = moved
                    ? DesktopWidgets.snapped(middle.x - root.width / 2, middle.y - root.height / 2, root.width, root.height,
                                             target.w, target.h, [], Theme.desktop.margin, Theme.desktop.gap, Theme.desktop.reach)
                    : at;
                const place = DesktopWidgets.dropped(local.x, local.y, root.width, root.height, target.w, target.h,
                                                     Theme.desktop.zoom);
                // The screen goes with the place, except the main one's, so those follow a new main.
                if (target.name !== "" && target.name !== (Screens.main?.name ?? ""))
                    place.screen = target.name;
                root.settling = true;
                Settings.values.desktopWidgets = DesktopWidgets.withPlace(Settings.values.desktopWidgets, root.name, place);
                root.moving = false;
                Qt.callLater(() => root.settling = false);
            }
        }
    }
}
