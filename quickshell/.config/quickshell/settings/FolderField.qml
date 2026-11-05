import QtQuick
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "../services/CaptureFolders.js" as CaptureFolders

// A folder setting (the wallpaper folder, the screenshots' and recordings'): a settings row with
// the folder in use as its subtitle, Choose… for a folder picker (zenity), and Default while
// another one is chosen. Until 2026-11-05 a text field with its instructions inside it.
SettingRow {
    id: root

    property string key      // the setting; empty means the default
    property string fallback // its default folder
    property string home

    readonly property string current: CaptureFolders.folder(Settings.values[key], home, fallback)
    readonly property bool custom: String(Settings.values[key] ?? "").trim() !== ""

    title: "Folder"
    subtitle: CaptureFolders.short(current, home) + (custom ? "" : " (the default)")

    Row {
        spacing: Theme.spacing.s

        TextButton {
            text: "Default"
            visible: root.custom
            onClicked: Settings.values[root.key] = ""
        }

        TextButton {
            text: "Choose…"
            filled: true
            enabled: !pick.running
            onClicked: pick.running = true
        }
    }

    // The picker opens in the folder in use; cancelling prints nothing and changes nothing.
    Process {
        id: pick
        command: ["zenity", "--file-selection", "--directory", "--title=Choose a folder", "--filename=" + root.current + "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path !== "")
                    Settings.values[root.key] = path;
            }
        }
    }
}
