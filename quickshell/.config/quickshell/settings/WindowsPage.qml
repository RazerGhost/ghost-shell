import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Windows: the gaps around them, their border and corners, and whether apps reopen where they
// were. Applied through Hyprland (HyprlandSettings.qml); snapping follows the gaps.
Column {
    id: page

    spacing: Theme.spacing.l

    readonly property var pixels: v => v === 0 ? "None" : v + " px"

    SettingGroup {
        title: "Look"

        SettingRow {
            title: "Gaps between windows"
            subtitle: "Also between snapped windows"

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

        SettingRow {
            title: "Border"
            subtitle: "In your wallpaper's colors"

            Stepper {
                label: "Border width"
                values: Array.from({ length: 7 }, (_, i) => i)
                value: Settings.values.borderSize
                format: page.pixels
                onPicked: v => Settings.values.borderSize = v
            }
        }

        SettingRow {
            title: "Rounded corners"

            Stepper {
                label: "Corner rounding"
                values: Array.from({ length: 13 }, (_, i) => i * 2)
                value: Settings.values.rounding
                format: page.pixels
                onPicked: v => Settings.values.rounding = v
            }
        }
    }

    SettingGroup {
        title: "Behaviour"

        SettingRow {
            title: "Reopen apps where they were"
            subtitle: "An app's window comes back at the position and size it had when it closed"

            Switch {
                label: "Reopen apps where they were"
                checked: Settings.values.rememberPositions
                onToggled: Settings.values.rememberPositions = !checked
            }
        }
    }
}
