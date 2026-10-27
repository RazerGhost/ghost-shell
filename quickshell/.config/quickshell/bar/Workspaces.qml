import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme

// Workspace indicators for one monitor: a dot per workspace, the active one stretched
// into a pill. Click to switch.
Row {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs + 2

    Repeater {
        // Hyprland.workspaces lists the existing workspaces, sorted by id.
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: dot

            required property HyprlandWorkspace modelData

            // Special workspaces (scratchpad) have negative ids; show only this monitor's normal ones.
            visible: modelData.id > 0 && modelData.monitor === root.monitor

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: modelData.active ? Theme.workspace.activeDot : Theme.workspace.dot
            implicitHeight: Theme.workspace.dot
            radius: Theme.radius.full
            color: modelData.urgent ? Colors.m3error
                 : modelData.active ? Colors.m3primary
                 : Colors.m3onSurfaceVariant
            opacity: modelData.active || modelData.urgent ? 1 : 0.5

            Behavior on implicitWidth {
                NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.anim.fast }
            }

            MouseArea {
                // Bigger hit area than the 8px dot, so it's easy to click.
                anchors.fill: parent
                anchors.margins: -Theme.spacing.xs
                cursorShape: Qt.PointingHandCursor
                // activate() sends the right dispatch for Lua and legacy Hyprland configs.
                onClicked: dot.modelData.activate()
            }
        }
    }
}
