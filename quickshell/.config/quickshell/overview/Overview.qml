import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "../services/WorkspaceSlots.js" as WorkspaceSlots
import "../services/WindowGrid.js" as WindowGrid

// The overview, like Windows' Task View (user's choice): Super+Tab, a three-finger swipe up, or
// the hot corner (HotCorner.qml).
// The current workspace's windows as live previews; click one (or pick it with the arrow keys and
// Enter) to switch to it, hover for × to close it. A strip at the bottom shows every workspace in use as a miniature: click one to go
// there, drag a window onto one to move it there, + for a new one. The minimized windows are a
// list in the bottom-left corner, click one to bring it back. Escape, Super+Tab again, a swipe
// down or a click on the background closes it.
Scope {
    id: root

    property bool open: false

    // Opens it with fresh window positions and sizes (Hyprland doesn't send them on its own).
    function show(): void {
        if (open)
            return;
        Hyprland.refreshToplevels();
        open = true;
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            if (root.open)
                root.open = false;
            else
                root.show();
        }

        function open(): void {
            root.show();
        }

        function close(): void {
            root.open = false;
        }
    }

    HotCorner {
        onTriggered: root.show()
    }

    PanelWindow {
        id: window

        readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
        readonly property HyprlandWorkspace workspace: monitor?.activeWorkspace ?? null
        // The monitor in logical pixels, for placing windows in the workspace miniatures.
        readonly property real monitorWidth: (monitor?.width ?? 1920) / (monitor?.scale ?? 1)
        readonly property real monitorHeight: (monitor?.height ?? 1080) / (monitor?.scale ?? 1)

        // The windows on a workspace with known positions, front ones last (drawn on top).
        function windowsOn(ws: HyprlandWorkspace): list<HyprlandToplevel> {
            return Windows.recent.filter(t => t.workspace === ws && t.lastIpcObject?.at).reverse();
        }

        // This workspace's windows, in a stable order (by position) so they don't jump around.
        readonly property list<HyprlandToplevel> windows: windowsOn(workspace)
            .sort((a, b) => a.lastIpcObject.at[1] - b.lastIpcObject.at[1] || a.lastIpcObject.at[0] - b.lastIpcObject.at[0])
        readonly property var rows: WindowGrid.grid(
            windows.map(t => ({ width: t.lastIpcObject.size[0], height: t.lastIpcObject.size[1] })),
            width - Theme.overview.margin * 2,
            height - Theme.island.reserved - Theme.overview.stripSpace - Theme.overview.margin * 2,
            Theme.overview.gap, Theme.overview.label)

        // The workspaces in the strip: the ones in use and the current one (like the island).
        readonly property var existing: Hyprland.workspaces.values.filter(ws => ws.monitor === monitor && ws.id > 0)
        readonly property var workspaceIds: WorkspaceSlots.used(existing.map(ws => ws.id), workspace?.id ?? 1)

        function go(id: int): void {
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        }

        visible: root.open
        screen: Quickshell.screens.find(s => s.name === monitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-overview"

        // Blur behind the whole dimmed desktop (ext-background-effect; see NOTES.md).
        BackgroundEffect.blurRegion: Region { item: dimmed }

        WlrLayershell.layer: WlrLayer.Overlay
        // OnDemand, not Exclusive: clicking a window focuses it as the overview closes, and
        // Hyprland refuses to focus windows while an exclusive surface exists (see Switcher).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // The window the arrow keys and Enter act on (an index into `windows`); the pointer moves
        // it too. Starts on the window you were using; stays in range when one moves away.
        property int selected: 0
        onWindowsChanged: selected = Math.min(selected, Math.max(0, windows.length - 1))

        onVisibleChanged: {
            if (visible) {
                selected = Math.max(0, windows.indexOf(Windows.active));
                keys.forceActiveFocus();
            }
        }

        // The dimmed (and blurred, see BackgroundEffect above) desktop. Click it to close.
        Rectangle {
            id: dimmed

            anchors.fill: parent
            color: Colors.scrim

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
        }

        // Arrow keys move the selection, Enter switches to it, Escape closes. 1-9 move the
        // selected window to that workspace, Shift+Left/Right to the one before or after this one;
        // the overview stays open, so you can sort several.
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: root.open = false
            Keys.onPressed: event => {
                const directions = { [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down" };
                const selectedWindow = window.windows[window.selected];
                const current = window.workspace?.id ?? 1;
                if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && selectedWindow) {
                    Windows.moveToWorkspace(selectedWindow, event.key - Qt.Key_0);
                    event.accepted = true;
                } else if ((event.modifiers & Qt.ShiftModifier) && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                    const target = current + (event.key === Qt.Key_Left ? -1 : 1);
                    if (selectedWindow && target >= 1)
                        Windows.moveToWorkspace(selectedWindow, target);
                    event.accepted = true;
                } else if (directions[event.key]) {
                    window.selected = WindowGrid.neighbour(window.rows, window.selected, directions[event.key]);
                    event.accepted = true;
                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && window.windows[window.selected]) {
                    root.open = false;
                    Windows.show(window.windows[window.selected]);
                    event.accepted = true;
                }
            }
        }

        // The windows, a centered grid between the island and the strip.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.island.reserved + Theme.overview.margin
               + (parent.height - Theme.island.reserved - Theme.overview.stripSpace - Theme.overview.margin * 2 - implicitHeight) / 2
            spacing: Theme.overview.gap

            Text {
                visible: window.windows.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No windows on this workspace"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.large
            }

            Repeater {
                model: root.open ? window.rows : []

                Row {
                    id: row

                    required property var modelData

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.overview.gap

                    Repeater {
                        model: row.modelData

                        // A fixed slot in the row; the card inside it can be dragged away.
                        Item {
                            id: slot

                            required property var modelData
                            readonly property HyprlandToplevel toplevel: window.windows[modelData.index] ?? null

                            width: modelData.width
                            height: modelData.height + Theme.overview.label

                            Item {
                                id: card

                                // Read by a workspace in the strip when the card is dropped on it.
                                readonly property HyprlandToplevel toplevel: slot.toplevel

                                // Where it was grabbed. While dragged it shrinks around that point
                                // to about a workspace miniature's size, so it doesn't cover the
                                // strip; that point (the pointer) decides where it's dropped.
                                property point grab: Qt.point(width / 2, height / 2)
                                readonly property real dragScale: Math.min(1, Theme.overview.workspace / width)

                                width: slot.width
                                height: slot.height
                                z: dragArea.drag.active ? 1 : 0

                                transform: Scale {
                                    origin.x: card.grab.x
                                    origin.y: card.grab.y
                                    xScale: dragArea.drag.active ? card.dragScale : 1
                                    yScale: xScale

                                    Behavior on xScale {
                                        NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
                                    }
                                }

                                Drag.active: dragArea.drag.active
                                Drag.keys: ["window"]
                                Drag.hotSpot: grab

                                Accessible.role: Accessible.Button
                                Accessible.name: slot.toplevel?.title ?? ""
                                Accessible.onPressAction: {
                                    root.open = false;
                                    Windows.show(slot.toplevel);
                                }

                                // Click: switch to it. Drag: onto a workspace in the strip. Under the
                                // preview, so its × gets its own clicks; the rest reaches this.
                                MouseArea {
                                    id: dragArea

                                    width: parent.width
                                    height: slot.modelData.height
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    drag.target: card
                                    onEntered: window.selected = slot.modelData.index
                                    onPressed: mouse => card.grab = Qt.point(mouse.x, mouse.y)
                                    onClicked: {
                                        root.open = false;
                                        Windows.show(slot.toplevel);
                                    }
                                    onReleased: {
                                        if (dragArea.drag.active)
                                            card.Drag.drop();
                                        card.x = 0;
                                        card.y = 0;
                                    }
                                }

                                WindowPreview {
                                    id: preview
                                    anchors.fill: parent
                                    toplevel: slot.toplevel
                                    previewHeight: slot.modelData.height
                                    highlighted: window.selected === slot.modelData.index
                                    capturing: root.open
                                    closable: true
                                }
                            }
                        }
                    }
                }
            }
        }

        // The minimized windows, in the bottom-left corner beside the strip.
        Surface {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacing.l
            width: Theme.overview.minimized
            height: minimized.implicitHeight + Theme.spacing.m * 2
            radius: Theme.radius.xl
            visible: root.open && Windows.minimized.length > 0

            MinimizedList {
                id: minimized
                x: Theme.spacing.m
                y: Theme.spacing.m
                width: parent.width - Theme.spacing.m * 2
                onRestored: root.open = false
            }
        }

        // The workspaces strip at the bottom.
        Surface {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacing.l
            width: strip.implicitWidth + Theme.spacing.m * 2
            height: strip.implicitHeight + Theme.spacing.m * 2
            radius: Theme.radius.xl

            Accessible.role: Accessible.List
            Accessible.name: "Workspaces"

            Row {
                id: strip
                anchors.centerIn: parent
                spacing: Theme.spacing.m

                Repeater {
                    model: root.open ? window.workspaceIds : []

                    // One workspace in miniature: its windows where they are on the screen.
                    MouseArea {
                        id: ws

                        required property int modelData
                        readonly property HyprlandWorkspace workspace: window.existing.find(w => w.id === modelData) ?? null
                        readonly property bool current: modelData === window.workspace?.id
                        readonly property real scale: width / window.monitorWidth

                        width: Theme.overview.workspace
                        height: Math.round(width * window.monitorHeight / window.monitorWidth)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.go(modelData)

                        Accessible.role: Accessible.Button
                        Accessible.name: "Workspace " + modelData + (current ? ", current" : "")
                        Accessible.onPressAction: window.go(modelData)

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: Theme.radius.m
                            color: Colors.m3surfaceContainer

                            Repeater {
                                model: ws.workspace ? window.windowsOn(ws.workspace) : []

                                ScreencopyView {
                                    required property HyprlandToplevel modelData
                                    x: (modelData.lastIpcObject.at[0] - (window.monitor?.x ?? 0)) * ws.scale
                                    y: (modelData.lastIpcObject.at[1] - (window.monitor?.y ?? 0)) * ws.scale
                                    width: modelData.lastIpcObject.size[0] * ws.scale
                                    height: modelData.lastIpcObject.size[1] * ws.scale
                                    captureSource: modelData.wayland
                                    live: false
                                    Component.onCompleted: captureFrame()
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius.m
                            color: "transparent"
                            border.width: ws.current || drop.containsDrag ? Theme.outline.strong : ws.containsMouse ? Theme.outline.normal : 0
                            border.color: ws.current || drop.containsDrag ? Colors.m3primary : Colors.m3onSurface
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: Theme.spacing.s
                            text: ws.modelData
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            font.weight: Font.DemiBold
                            style: Text.Outline
                            styleColor: Colors.m3surface
                        }

                        // Drop a window here to move it to this workspace.
                        DropArea {
                            id: drop
                            anchors.fill: parent
                            keys: ["window"]
                            onDropped: drop => Windows.moveToWorkspace(drop.source.toplevel, ws.modelData)
                        }
                    }
                }

                // A new, empty workspace: the first number not in use.
                MouseArea {
                    id: add

                    readonly property int next: {
                        let id = 1;
                        while (window.workspaceIds.includes(id))
                            id++;
                        return id;
                    }

                    width: Theme.overview.workspace / 2
                    height: Math.round(Theme.overview.workspace * window.monitorHeight / window.monitorWidth)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.go(next)

                    Accessible.role: Accessible.Button
                    Accessible.name: "New workspace"
                    Accessible.onPressAction: window.go(next)

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius.m
                        color: Colors.m3surfaceContainer
                        border.width: add.containsMouse || addDrop.containsDrag ? Theme.outline.normal : 0
                        border.color: Colors.m3onSurface
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: "add"
                    }

                    // Drop a window here to give it a workspace of its own.
                    DropArea {
                        id: addDrop
                        anchors.fill: parent
                        keys: ["window"]
                        onDropped: drop => Windows.moveToWorkspace(drop.source.toplevel, add.next)
                    }
                }
            }
        }
    }
}
