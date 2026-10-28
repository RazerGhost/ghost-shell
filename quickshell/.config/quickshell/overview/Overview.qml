import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "../bar/WorkspaceSlots.js" as WorkspaceSlots
import "OverviewLayout.js" as OverviewLayout

// The overview, like Windows' Task View (user's choice): Super+Tab or a three-finger swipe up.
// The current workspace's windows as live previews; click one to switch to it, hover for × to
// close it. A strip at the bottom shows every workspace in use as a miniature: click one to go
// there, drag a window onto one to move it there, + for a new one. Escape, Super+Tab again, a
// swipe down or a click on the background closes it.
Scope {
    id: root

    property bool open: false

    IpcHandler {
        target: "overview"

        function toggle(): void {
            if (!root.open)
                Hyprland.refreshToplevels(); // fresh window positions and sizes
            root.open = !root.open;
        }

        function open(): void {
            if (!root.open) {
                Hyprland.refreshToplevels();
                root.open = true;
            }
        }

        function close(): void {
            root.open = false;
        }
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
        readonly property var rows: OverviewLayout.grid(
            windows.map(t => ({ width: t.lastIpcObject.size[0], height: t.lastIpcObject.size[1] })),
            width - Theme.overview.margin * 2,
            height - Theme.island.height - Theme.overview.stripSpace - Theme.overview.margin * 2,
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
        WlrLayershell.layer: WlrLayer.Overlay
        // OnDemand, not Exclusive: clicking a window focuses it as the overview closes, and
        // Hyprland refuses to focus windows while an exclusive surface exists (see Switcher).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        onVisibleChanged: {
            if (visible)
                keys.forceActiveFocus();
        }

        // The dimmed (and, through the layer rule, blurred) desktop. Click it to close.
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.45

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: root.open = false
        }

        // The windows, a centered grid between the island and the strip.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.island.height + Theme.overview.margin
               + (parent.height - Theme.island.height - Theme.overview.stripSpace - Theme.overview.margin * 2 - implicitHeight) / 2
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

                                width: slot.width
                                height: slot.height
                                z: dragArea.drag.active ? 1 : 0

                                Drag.active: dragArea.drag.active
                                Drag.keys: ["window"]
                                Drag.hotSpot: Qt.point(width / 2, height / 2)

                                Accessible.role: Accessible.Button
                                Accessible.name: slot.toplevel?.title ?? ""
                                Accessible.onPressAction: {
                                    root.open = false;
                                    Windows.show(slot.toplevel);
                                }

                                Rectangle {
                                    id: frame
                                    width: parent.width
                                    height: slot.modelData.height
                                    radius: Theme.radius.m
                                    color: Colors.m3surfaceContainerHigh
                                    border.width: hover.hovered ? 3 : 0
                                    border.color: Colors.m3primary

                                    ScreencopyView {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        captureSource: root.open ? slot.toplevel?.wayland ?? null : null
                                        live: true
                                    }
                                }

                                Row {
                                    anchors.top: frame.bottom
                                    anchors.topMargin: Theme.spacing.s
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(implicitWidth, parent.width)
                                    spacing: Theme.spacing.s

                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitSize: Theme.icon.normal
                                        source: Quickshell.iconPath(Windows.iconFor(slot.toplevel), "application-x-executable")
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(implicitWidth, card.width - Theme.icon.normal - parent.spacing)
                                        text: slot.toplevel?.title ?? ""
                                        color: Colors.m3onSurface
                                        font.family: Theme.font.sans
                                        font.pixelSize: Theme.font.normal
                                        elide: Text.ElideRight
                                    }
                                }

                                // Over the whole card, the × button included.
                                HoverHandler {
                                    id: hover
                                }

                                // Click: switch to it. Drag: onto a workspace in the strip.
                                MouseArea {
                                    id: dragArea

                                    anchors.fill: frame
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    drag.target: card
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

                                IconButton {
                                    anchors.top: frame.top
                                    anchors.right: frame.right
                                    anchors.margins: Theme.spacing.s
                                    visible: hover.hovered
                                    icon: "close"
                                    label: "Close " + (slot.toplevel?.title ?? "window")
                                    color: Colors.m3onSurface
                                    onClicked: Windows.close(slot.toplevel)

                                    Rectangle {
                                        anchors.fill: parent
                                        z: -1
                                        radius: Theme.radius.full
                                        color: Colors.surfaceTranslucent
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // The workspaces strip at the bottom.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacing.l
            width: strip.implicitWidth + Theme.spacing.m * 2
            height: strip.implicitHeight + Theme.spacing.m * 2
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent

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
                            border.width: ws.current || drop.containsDrag ? 3 : ws.containsMouse ? 2 : 0
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
                        border.width: add.containsMouse || addDrop.containsDrag ? 2 : 0
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
