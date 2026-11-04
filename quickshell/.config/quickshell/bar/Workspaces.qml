import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import "../services/WorkspaceSlots.js" as WorkspaceSlots

// Workspace dots for one monitor, which the island shows for a moment when the workspace changes
// (IslandWindow.qml): workspaces 1 to Theme.workspace.minimum and any higher one in use (or only
// the ones in use, Settings' workspaceDots 0). Empty ones are dimmed; the active one stretches
// into a pill. Click a dot to go there; `scroll()` steps through them (the island passes its
// wheel events). `hovered` keeps them shown while the pointer is on them.
Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property alias hovered: wheelArea.containsMouse
    readonly property int active: WorkspaceSlots.idOf(monitor?.activeWorkspace) ?? 1

    // This monitor's workspaces, by id. Hyprland.workspaces only lists ones that exist.
    readonly property var existing: {
        const byId = {};
        for (const ws of Hyprland.workspaces.values) {
            if (ws.monitor === monitor)
                byId[WorkspaceSlots.idOf(ws)] = ws;
        }
        return byId;
    }
    // Every workspace you can scroll or click to. With Settings' "only the ones in use", just
    // those (and the one you're on).
    readonly property var slots: Theme.workspace.minimum === 0
        ? WorkspaceSlots.used(Object.keys(existing).map(Number), active)
        : WorkspaceSlots.slots(Theme.workspace.minimum, Object.keys(existing).map(Number))


    // Works for workspaces that don't exist yet, unlike HyprlandWorkspace.activate().
    // The string is Lua because the Hyprland config is (same dispatch as binds.lua).
    function go(id: int): void {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    // A wheel event's angleDelta.y. Touchpads send many small scroll events; step once per
    // notch-sized amount.
    property real accumulated: 0
    function scroll(delta: real): void {
        accumulated += delta;
        if (Math.abs(accumulated) >= 120) {
            go(WorkspaceSlots.stepIn(slots, active, accumulated > 0 ? -1 : 1));
            accumulated = 0;
        }
    }

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: dots.implicitWidth
    implicitHeight: Theme.island.height

    // Only to know whether the pointer is on the dots; it takes no buttons, so clicks reach them.
    MouseArea {
        id: wheelArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }

    Row {
        id: dots

        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.workspace.spacing

        Repeater {
            model: root.slots

            delegate: Rectangle {
                id: dot

                required property int modelData
                readonly property HyprlandWorkspace workspace: root.existing[modelData] ?? null
                readonly property bool isActive: modelData === root.active
                readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: isActive ? Theme.workspace.activeDot : Theme.workspace.dot
                implicitHeight: Theme.workspace.dot
                radius: Theme.radius.full
                color: workspace?.urgent ? Colors.m3error
                     : isActive ? Colors.m3primary
                     : Colors.m3onSurfaceVariant
                opacity: isActive || occupied || workspace?.urgent ? 1 : 0.35

                Accessible.role: Accessible.Button
                Accessible.name: "Workspace " + modelData + (isActive ? ", current" : occupied ? "" : ", empty")
                Accessible.onPressAction: root.go(modelData)

                Behavior on implicitWidth {
                    NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.anim.fast }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim.fast }
                }

                MouseArea {
                    // Bigger hit area than the 8px dot, so it's easy to click.
                    anchors.fill: parent
                    anchors.margins: -Theme.spacing.xs
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(dot.modelData)
                }
            }
        }
    }
}
