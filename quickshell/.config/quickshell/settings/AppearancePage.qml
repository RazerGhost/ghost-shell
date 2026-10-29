import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Appearance: the wallpaper (the colors of everything come from it), light or dark, the shell's panels (glass
// or nearly solid: Colors.surfaceTranslucent, widgets/Surface.qml), and the windows' border and
// corners (applied through Hyprland, HyprlandSettings.qml).
Column {
    id: page

    spacing: Theme.spacing.l

    readonly property var pixels: v => v === 0 ? "None" : v + " px"

    SettingGroup {
        title: "Wallpaper"

        SettingRow {
            title: Wallpaper.path ? Wallpaper.path.split("/").pop() : "Hyprland's default"
            subtitle: "The colors of the shell, Hyprland and your apps come from it"

            TextButton {
                text: "Change"
                onClicked: Wallpaper.pickerOpen = true
            }
        }

        SettingRow {
            title: "Light or dark"
            subtitle: Settings.values.colorScheme !== "auto" ? "For the shell, Hyprland and your apps"
                    : Weather.current?.sunset != null ? "Dark from sunset to sunrise in " + Weather.place.name
                    : "Dark from 19:00 to 07:00 (set a weather town to follow sunset)"

            Stepper {
                label: "Light or dark"
                values: ["dark", "light", "auto"]
                value: Settings.values.colorScheme
                format: v => ({ dark: "Dark", light: "Light", auto: "At sunset" })[v]
                onPicked: v => Settings.values.colorScheme = v
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
            title: "Blur style"
            subtitle: "Behind the glass, menus and see-through windows"

            Stepper {
                label: "Blur style"
                values: ["kawase", "frost", "acrylic", "prism", "aurora", "haze"]
                value: Settings.values.blurStyle
                format: v => ({ kawase: "Classic", frost: "Frost", acrylic: "Acrylic", prism: "Prism",
                                aurora: "Aurora", haze: "Haze" })[v] ?? v
                onPicked: v => Settings.values.blurStyle = v
            }
        }

        SettingRow {
            visible: Settings.values.glass
            title: "See-through"
            subtitle: "How solid the glass is"

            Stepper {
                label: "Glass opacity"
                // 20-85 % (user's choice). The blur doesn't depend on it: each panel asks for blur
                // behind its cards (BackgroundEffect), whatever their opacity.
                values: Array.from({ length: 14 }, (_, i) => 20 + i * 5)
                value: Settings.values.glassOpacity
                format: v => v + " %"
                onPicked: v => Settings.values.glassOpacity = v
            }
        }
    }

    SettingGroup {
        title: "Windows"

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
}
