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
// it). Right-click: menu.
MouseArea {
    id: root

    // { id, pinned, windows: [{ appId, window }] } from DockApps.items.
    required property var item
    readonly property DesktopEntry entry: item.id.startsWith("app:") ? null : DesktopEntries.byId(item.id)
    readonly property list<HyprlandToplevel> windows: item.windows.map(w => w.window)
    readonly property bool focused: windows.includes(Windows.active)
    readonly property string name: entry?.name ?? windows[0]?.title ?? item.id
    readonly property int badge: DockApps.notificationCount(
        Notifications.history.map(n => ({ desktopEntry: n.desktopEntry, appName: n.appName })), item.id, name)
    // Set by DockBar while this app's window previews show: they replace the name label.
    property bool previewing: false

    signal menuRequested()

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
        else
            activate();
    }

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
        opacity: root.containsMouse && !root.previewing ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fast }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.name
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }
}
