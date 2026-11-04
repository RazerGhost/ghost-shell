import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "DockApps.js" as DockApps

// One app in the dock: its icon, a dot per open window (up to three; the focused app's are in the
// accent color), a badge with its notifications in the today menu's history, and its name above it
// on hover (DockBar shows window previews instead for apps with windows). Click: open the
// app, or switch to it (again to cycle its windows; on the focused app's only window, minimize
// it). Right-click: menu. Drag it along the dock to move it among the pinned apps (pinning a
// running one), or up off the dock to unpin it, like macOS (DockBar does the dropping).
MouseArea {
    id: root

    // { id, pinned, windows: [{ appId, window }] } from DockApps.items.
    required property var item
    // Reading the app list makes this look again once it has filled in (it does so a moment after
    // the shell starts, NOTES): byId alone was asked once, and pinned apps kept the generic icon
    // until they ran.
    readonly property DesktopEntry entry: {
        void DesktopEntries.applications.values;
        return item.id.startsWith("app:") ? null : DesktopEntries.byId(item.id);
    }
    readonly property list<HyprlandToplevel> windows: item.windows.map(w => w.window)
    readonly property bool focused: windows.includes(Windows.active)
    readonly property string name: entry?.name ?? windows[0]?.title ?? item.id
    readonly property int badge: DockApps.notificationCount(
        Notifications.history.map(n => ({ desktopEntry: n.desktopEntry, appName: Notifications.appOf(n) })), item.id, name)
    // Set by DockBar while this app's window previews show: they replace the name label.
    property bool previewing: false

    // How far the icon has been dragged from where it was pressed, while dragging.
    property point dragOffset: Qt.point(0, 0)
    property bool dragging: false
    property point pressedAt
    // Up this far, a pinned app shows "Remove" and is unpinned when let go.
    readonly property bool removing: dragging && item.pinned && dragOffset.y < -Theme.dock.height

    signal menuRequested()
    signal dropped(real dx, real dy)

    function activate(): void {
        const target = DockApps.clickTarget(windows, Windows.active);
        if (target === "") {
            if (entry)
                Apps.launch(entry);
        } else if (target === "minimize") {
            Windows.minimize(Windows.active);
        } else {
            Windows.show(target);
        }
    }

    implicitWidth: Theme.dock.icon + Theme.spacing.m
    implicitHeight: Theme.dock.height
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            menuRequested();
        else if (!dragged)
            activate();
    }

    // A move of a few px past the press starts a drag; a drag ends without a click.
    property bool dragged: false
    onPressed: mouse => {
        pressedAt = Qt.point(mouse.x, mouse.y);
        dragged = false;
    }
    onPositionChanged: mouse => {
        if (!(mouse.buttons & Qt.LeftButton))
            return;
        const dx = mouse.x - pressedAt.x, dy = mouse.y - pressedAt.y;
        if (!dragging && Math.hypot(dx, dy) > Theme.spacing.m)
            dragging = dragged = true;
        if (dragging)
            dragOffset = Qt.point(dx, dy);
    }
    onReleased: {
        if (!dragging)
            return;
        dropped(dragOffset.x, dragOffset.y);
        endDrag();
    }
    // The grab taken away (another surface, a closed window rebuilding the dock's items): the
    // drag just ends, so the dock doesn't stay shown for it.
    onCanceled: endDrag()

    function endDrag(): void {
        dragging = false;
        dragOffset = Qt.point(0, 0);
    }
    z: dragging ? 1 : 0

    Accessible.role: Accessible.Button
    Accessible.name: name + (windows.length > 0 ? ", " + windows.length + " open" : "")
                     + (badge > 0 ? ", " + badge + (badge === 1 ? " notification" : " notifications") : "")
    Accessible.onPressAction: activate()

    // Above the dots; lifts a little while hovered.
    IconImage {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.containsMouse ? -Theme.spacing.xs : -2
        implicitSize: Theme.dock.icon
        // Follows the pointer while dragged, fading while it would be removed.
        transform: Translate { x: root.dragOffset.x; y: root.dragOffset.y }
        opacity: root.removing ? Theme.state.disabled : 1

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
        }
        source: Quickshell.iconPath(root.entry?.icon || root.windows[0]?.wayland?.appId || "application-x-executable", "application-x-executable")
    }

    // The app's notifications, a badge on the icon's corner.
    Rectangle {
        visible: root.badge > 0
        anchors.horizontalCenter: icon.right
        anchors.horizontalCenterOffset: -Theme.spacing.xs
        anchors.verticalCenter: icon.top
        anchors.verticalCenterOffset: Theme.spacing.xs
        width: Math.max(height, count.implicitWidth + Theme.spacing.s)
        height: Theme.dock.badge
        radius: height / 2
        color: Colors.m3error

        Text {
            id: count
            anchors.centerIn: parent
            text: root.badge > 9 ? "9+" : root.badge
            color: Colors.m3onError
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
        }
    }

    // Open windows: one dot each, up to three, between the icon and the bar's edge.
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.xs
        spacing: 3

        Repeater {
            model: Math.min(root.windows.length, 3)

            Rectangle {
                width: root.focused ? Theme.spacing.m : Theme.spacing.xs
                height: Theme.spacing.xs
                radius: height / 2
                color: root.focused ? Colors.m3primary : Colors.m3onSurfaceVariant

                Behavior on width {
                    NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
                }
            }
        }
    }

    // The app's name above the icon while hovered.
    Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Theme.spacing.s
        width: label.implicitWidth + Theme.spacing.m * 2
        height: label.implicitHeight + Theme.spacing.xs * 2
        radius: Theme.radius.full
        opacity: root.removing || (root.containsMouse && !root.previewing && !root.dragging) ? 1 : 0
        visible: opacity > 0
        transform: Translate { x: root.dragOffset.x; y: root.dragOffset.y }

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fast }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.removing ? "Remove " + root.name : root.name
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }
}
