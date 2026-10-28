import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Windows: the gaps around tiled windows (applied through Hyprland, HyprlandSettings.qml), the
// hot corner, and whether floating apps reopen where they were. Their border and corners are on
// the Appearance page.
Column {
    id: page

    spacing: Theme.spacing.l

    readonly property var pixels: v => v === 0 ? "None" : v + " px"

    SettingGroup {
        title: "Tiling"

        SettingRow {
            title: "Gaps between windows"

            Stepper {
                label: "Gaps between windows"
                values: Array.from({ length: 21 }, (_, i) => i)
                value: Settings.values.gapsIn
                format: page.pixels
                onPicked: v => Settings.values.gapsIn = v
            }
        }

        SettingRow {
            title: "Gaps at the screen's edges"

            Stepper {
                label: "Gaps at the screen's edges"
                values: Array.from({ length: 21 }, (_, i) => i * 2)
                value: Settings.values.gapsOut
                format: page.pixels
                onPicked: v => Settings.values.gapsOut = v
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
