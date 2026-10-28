import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// The dock on one monitor, macOS style (user's choice): a rounded bar floating a little above the
// bottom edge. It's shown on an empty desktop
// and slides down out of sight while a window covers its area (or one is fullscreen); touching
// the bottom edge with the pointer brings it back.
PanelWindow {
    id: window

    required property var dock // Dock.qml: items, pinned, togglePin()
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    // The bar, centered at the bottom.
    readonly property real bodyWidth: row.implicitWidth + Theme.spacing.m * 2
    readonly property real bodyHeight: Theme.dock.height

    // Whether a window on this monitor's workspace overlaps the dock (or is fullscreen).
    // Positions come from Hyprland (Dock.qml keeps them fresh), in global coordinates.
    readonly property bool covered: {
        const ws = monitor?.activeWorkspace;
        if (!ws)
            return false;
        const left = (monitor.x ?? 0) + (width - bodyWidth) / 2;
        const right = left + bodyWidth;
        const top = (monitor.y ?? 0) + height - bodyHeight - Theme.dock.margin;
        for (const t of Hyprland.toplevels.values) {
            const info = t.lastIpcObject;
            if (t.workspace !== ws || !info?.at || info.hidden)
                continue;
            if (info.fullscreen > 0)
                return true;
            const [x, y] = info.at;
            const [w, h] = info.size;
            if (x < right && x + w > left && y + h > top)
                return true;
        }
        return false;
    }

    // The pointer is at the bottom edge or on the dock, or its menu is open. Stays true for a
    // moment after the pointer leaves, so the dock doesn't flicker away.
    readonly property bool wanted: trigger.containsMouse || hitArea.containsMouse || menu.visible
    property bool revealed: false
    onWantedChanged: {
        if (wanted) {
            hideDelay.stop();
            revealed = true;
        } else {
            hideDelay.restart();
        }
    }

    readonly property bool shown: !covered || revealed

    Timer {
        id: hideDelay
        interval: Theme.dock.hideDelay
        onTriggered: window.revealed = false
    }

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    // Room above the dock for the tooltips and the right-click menu.
    implicitHeight: Theme.dock.height + Theme.dock.margin + Theme.dock.menuSpace
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Input only on the dock (or, while hidden, the thin strip at the bottom edge) and the menu.
    // While shown it's hitArea: where the dock ends up, down to the screen edge. Not the sliding
    // bar itself: right after the reveal that's still below the screen, the pointer would be
    // outside the input area, and the dock would take that as the pointer leaving and hide again.
    mask: Region {
        item: window.shown ? hitArea : trigger

        Region {
            item: menu.visible ? menu : null
        }
    }

    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Closes the menu when you click anywhere else.
    HyprlandFocusGrab {
        windows: [window]
        active: menu.visible
        onCleared: menu.item = null
    }

    // The bottom edge: touch it to bring a hidden dock back.
    MouseArea {
        id: trigger
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: window.bodyWidth
        height: Theme.dock.trigger
        hoverEnabled: true
    }

    // Where the shown dock is, down to the screen edge (so the pointer can go from the edge to the
    // dock without leaving it). A MouseArea to know whether the pointer is on the dock; clicks go
    // to the icons inside it. It doesn't move; the bar and icons slide inside it.
    MouseArea {
        id: hitArea

        anchors.horizontalCenter: parent.horizontalCenter
        y: window.height - height
        width: window.bodyWidth
        height: window.bodyHeight + Theme.dock.margin
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        // The bar. Slides down out of sight while hidden.
        Rectangle {
            id: shape

            y: window.shown ? 0 : hitArea.height + Theme.spacing.s
            width: parent.width
            height: window.bodyHeight
            radius: Theme.dock.radius
            color: Colors.surfaceTranslucent

            Behavior on y {
                MorphAnimation {}
            }
        }

        // The apps, on the bar.
        Item {
            id: content

            y: shape.y
            width: parent.width
            height: window.bodyHeight

            Row {
                id: row
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height

                Repeater {
                    // Recomputed every second (window positions); ScriptModel keeps the icons
                    // whose app didn't change instead of rebuilding them all.
                    model: ScriptModel { values: window.dock.items }

                    Row {
                        id: slot

                        required property var modelData
                        required property int index

                        height: row.height

                        // A thin line between the pinned apps and the other running ones.
                        Rectangle {
                            visible: slot.index > 0 && !slot.modelData.pinned && window.dock.items[slot.index - 1].pinned
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: Theme.dock.icon * 0.6
                            color: Colors.m3outlineVariant
                        }

                        DockItem {
                            item: slot.modelData
                            onMenuRequested: {
                                menu.item = slot.modelData;
                                menu.anchorX = mapToItem(window.contentItem, width / 2, 0).x;
                            }
                        }
                    }
                }
            }
        }
    }

    // Right-click menu: new window, pin or unpin, close the app's windows.
    Rectangle {
        id: menu

        property var item: null
        property real anchorX
        readonly property DesktopEntry entry: item && !item.id.startsWith("app:") ? DesktopEntries.byId(item.id) : null

        function run(action: var): void {
            action();
            item = null;
        }

        visible: item !== null
        x: Math.max(Theme.spacing.s, Math.min(window.width - width - Theme.spacing.s, anchorX - width / 2))
        y: hitArea.y - height
        width: Theme.dock.menuWidth
        height: actions.implicitHeight + Theme.spacing.s * 2
        radius: Theme.radius.l
        color: Colors.surfaceTranslucent

        Column {
            id: actions
            anchors.centerIn: parent
            width: parent.width - Theme.spacing.s * 2

            component MenuRow: MouseArea {
                id: entryRow
                property string icon
                property string text
                width: parent.width
                height: Theme.list.rowHeight - Theme.spacing.m
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.MenuItem
                Accessible.name: text

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.m
                    color: Colors.m3onSurface
                    opacity: entryRow.containsMouse ? Theme.state.hover : 0
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.m
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.m

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: entryRow.icon
                        font.pixelSize: Theme.icon.small
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: entryRow.text
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                    }
                }
            }

            MenuRow {
                visible: menu.entry !== null
                icon: "add"
                text: "New window"
                onClicked: menu.run(() => Apps.launch(menu.entry))
            }

            // The app's own shortcuts from its .desktop file ("New Private Window", Steam's
            // "Library"). Its "New Window" is the row above already.
            Repeater {
                model: (menu.entry?.actions ?? []).filter(a => a.name.toLowerCase() !== "new window")

                MenuRow {
                    required property DesktopAction modelData
                    icon: "open_in_new"
                    text: modelData.name
                    onClicked: menu.run(() => modelData.execute())
                }
            }

            MenuRow {
                visible: menu.entry !== null
                icon: menu.item?.pinned ? "keep_off" : "keep"
                text: menu.item?.pinned ? "Unpin from dock" : "Pin to dock"
                onClicked: menu.run(() => window.dock.togglePin(menu.item.id))
            }

            MenuRow {
                visible: (menu.item?.windows.length ?? 0) > 0
                icon: "close"
                text: (menu.item?.windows.length ?? 0) > 1 ? "Close all windows" : "Close window"
                onClicked: menu.run(() => menu.item.windows.forEach(w => Windows.close(w.window)))
            }
        }
    }
}
