import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Windows: the gaps around tiled windows, their border and corners, and whether floating apps
// reopen where they were (applied through Hyprland, HyprlandSettings.qml); and the shell's panels:
// glass or nearly solid (Colors.surfaceTranslucent, widgets/Surface.qml).
Column {
    id: page

    spacing: Theme.spacing.l

    readonly property var pixels: v => v === 0 ? "None" : v + " px"

    SettingGroup {
        title: "Look"

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
        title: "Shell panels"

        SettingRow {
            title: "Glass"
            subtitle: "The island, menus, dock and launcher are see-through, with a thin light edge"

            Switch {
                label: "Glass panels"
                checked: Settings.values.glass
                onToggled: Settings.values.glass = !checked
            }
        }

        SettingRow {
            visible: Settings.values.glass
            title: "See-through"
            subtitle: "How solid the glass is"

            Stepper {
                label: "Glass opacity"
                // Not below 35 %: the blur rules skip pixels under 30 % (ignore_alpha in rules.lua).
                values: Array.from({ length: 11 }, (_, i) => 35 + i * 5)
                value: Settings.values.glassOpacity
                format: v => v + " %"
                onPicked: v => Settings.values.glassOpacity = v
            }
        }
    }

    SettingGroup {
        title: "Behaviour"

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
