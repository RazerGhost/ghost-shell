import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import "WorkspaceSlots.js" as WorkspaceSlots

// Workspace dots for one monitor: one per workspace in use, plus the one you're on (user's
// choice), so there are usually only a few. The active one stretches into a pill. Click a dot to
// go there; scroll to step through workspaces 1 to Theme.workspace.minimum (and higher ones in
// use). `hovered` tells the island to show all of them as numbers (WorkspaceNumbers.qml).
Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property alias hovered: wheelArea.containsMouse
    readonly property int active: monitor?.activeWorkspace?.id ?? 1

    // This monitor's workspaces, by id. Hyprland.workspaces only lists ones that exist.
    readonly property var existing: {
        const byId = {};
        for (const ws of Hyprland.workspaces.values) {
            if (ws.monitor === monitor)
                byId[ws.id] = ws;
        }
        return byId;
    }
    // Every workspace you can scroll or click to (the numbers on hover), and the ones with dots.
    readonly property var slots: WorkspaceSlots.slots(Theme.workspace.minimum, Object.keys(existing).map(Number))
    readonly property var usedSlots: WorkspaceSlots.used(Object.keys(existing).map(Number), active)


    // Works for workspaces that don't exist yet, unlike HyprlandWorkspace.activate().
    // The string is Lua because the Hyprland config is (same dispatch as binds.lua).
    function go(id: int): void {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: dots.implicitWidth
    // As tall as the island, not just the 8px dots, so scrolling anywhere over them works.
    implicitHeight: Theme.island.height

    // Scrolling over the dots steps through workspaces. A MouseArea under the dots, not a
    // WheelHandler: the WheelHandler never received wheel events here. It takes no buttons, so
    // clicks still reach the dots.
    MouseArea {
        id: wheelArea

        property real accumulated: 0

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onWheel: wheel => {
            // Touchpads send many small scroll events; step once per notch-sized amount.
            accumulated += wheel.angleDelta.y;
            if (Math.abs(accumulated) >= 120) {
                root.go(WorkspaceSlots.step(root.active, accumulated > 0 ? -1 : 1, root.slots.length));
                accumulated = 0;
            }
        }
    }

    Row {
        id: dots

        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.workspace.spacing

        Repeater {
            model: root.usedSlots

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
