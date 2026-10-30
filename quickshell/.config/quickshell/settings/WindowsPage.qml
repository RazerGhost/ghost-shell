import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// Windows: the buttons for the windows editor and the dock and island editor (customize/: the
// windows' look, gaps and motion, the dock and island), the hot corner, and whether floating
// apps reopen where they were.
Column {
    id: page

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Windows' look"

        SettingRow {
            title: "Customize the windows"
            subtitle: "Borders, corners, gaps and animations, shown on your windows"

            TextButton {
                text: "Customize"
                filled: true
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "customize", "windows"])
            }
        }
    }

    SettingGroup {
        title: "Dock and island"

        SettingRow {
            title: "Customize the dock and island"
            subtitle: "When the dock shows, its icons, the workspace dots, the island's clock and status icons, on the screen itself"

            TextButton {
                text: "Customize"
                filled: true
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "customize", "dock"])
            }
        }
    }

    SettingGroup {
        title: "Behaviour"

        SettingRow {
            title: "Hot corner"
            subtitle: "Resting the pointer in the top-left corner opens the overview"

            Switch {
                label: "Hot corner"
                checked: Settings.values.hotCorner
                onToggled: Settings.values.hotCorner = !checked
            }
        }

        SettingRow {
            title: "Reopen floating apps where they were"
            subtitle: "A floating window comes back at the position and size it had when it closed"

            Switch {
                label: "Reopen floating apps where they were"
                checked: Settings.values.rememberPositions
                onToggled: Settings.values.rememberPositions = !checked
            }
        }
    }
}
