import QtQuick
import Quickshell.Io
import qs.theme
import "Keybinds.js" as Keybinds

// Every keybind with what it does, read from Hyprland (`hyprctl binds -j`), so the list always
// matches hypr/binds.lua. Re-read each time the page is shown.
Column {
    id: root

    property var rows: []

    spacing: Theme.spacing.l
    onVisibleChanged: {
        if (visible)
            read.running = true;
    }
    Component.onCompleted: read.running = true

    Process {
        id: read
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.rows = Keybinds.rows(JSON.parse(text))
        }
    }

    Text {
        width: parent.width
        leftPadding: Theme.spacing.l
        text: "Change them in hypr/binds.lua in the dotfiles."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
    }

    SettingGroup {
        Repeater {
            model: root.rows

            SettingRow {
                id: bindRow

                required property var modelData

                implicitHeight: Theme.list.rowHeight
                title: modelData.description

                Text {
                    text: bindRow.modelData.keys
                    color: Colors.m3primary
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    font.weight: Font.Medium
                }
            }
        }
    }
}
