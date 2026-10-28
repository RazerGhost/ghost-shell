import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.theme

// The minimized windows, in the window menu and when hovering the workspace dots. Click one to
// bring it back to the current workspace.
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
