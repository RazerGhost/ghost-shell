import QtQuick
import Quickshell.Hyprland
import qs.controlcenter
import qs.services
import qs.theme

// The minimized windows, in the overview's bottom-left corner (Overview.qml; until 2026-11-03
// under the island's workspace numbers on hover). Click one to bring it back to the current
// workspace.
Column {
    id: root

    // A window was restored.
    signal restored()

    visible: Windows.minimized.length > 0
    spacing: Theme.spacing.xs

    Text {
        text: "Minimized"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
    }

    Repeater {
        model: Windows.minimized

        ListRow {
            required property HyprlandToplevel modelData

            width: root.width
            appIcon: Windows.iconFor(modelData)
            title: modelData.title
            subtitle: "Click to restore"
            onActivated: {
                Windows.restore(modelData);
                root.restored();
            }
        }
    }
}
