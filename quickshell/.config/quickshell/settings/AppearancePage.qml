import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "../services/ColorScheme.js" as ColorSchemeJs
import "HyprlandConfig.js" as HyprlandConfig
import "../theme/ThemeScale.js" as ThemeScale

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

        Item {
            width: parent.width
            height: wallpaperFolder.height + Theme.spacing.m * 2

            FolderField {
                id: wallpaperFolder
                x: Theme.spacing.m
                y: Theme.spacing.m
                width: parent.width - Theme.spacing.m * 2
                key: "wallpaperFolder"
                fallback: Quickshell.env("HOME") + "/Pictures/Wallpapers"
                home: Quickshell.env("HOME")
            }
        }

        SettingRow {
            title: "Change it every"
            subtitle: Settings.values.wallpaperMinutes > 0 ? "A random one; the colors change with it" : "Off"

            Stepper {
                label: "Change the wallpaper every"
                values: [0, 15, 30, 60, 120, 240]
                value: Settings.values.wallpaperMinutes
                format: v => v === 0 ? "Never" : v < 60 ? v + " min" : (v / 60) + " h"
                onPicked: v => Settings.values.wallpaperMinutes = v
            }
        }

        SettingRow {
            enabled: Settings.values.wallpaperMinutes > 0
            title: "From all pictures"
            subtitle: "Off: only from your folder"

            Switch {
                label: "Slideshow from all pictures"
                checked: Settings.values.wallpaperSlideshowAll
                onToggled: Settings.values.wallpaperSlideshowAll = !checked
            }
        }

        SettingRow {
            title: "Follow light and dark"
            subtitle: "A picture that comes with a dark version (some of KDE's) switches with the mode"

            Switch {
                label: "Wallpaper follows light and dark"
                checked: Settings.values.wallpaperFollowsMode
                onToggled: Settings.values.wallpaperFollowsMode = !checked
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

        SettingRow {
            title: "Color style"
            subtitle: "How the colors are drawn from the wallpaper (matugen)"

            Stepper {
                label: "Color style"
                values: ColorSchemeJs.styles
                valueWidth: Theme.settings.stepperWide
                value: Settings.values.colorStyle
                format: v => ({
                    "scheme-tonal-spot": "Tonal (default)", "scheme-vibrant": "Vibrant",
                    "scheme-expressive": "Expressive", "scheme-content": "Content",
                    "scheme-fidelity": "Faithful", "scheme-fruit-salad": "Fruit salad",
                    "scheme-rainbow": "Rainbow", "scheme-neutral": "Neutral",
                    "scheme-monochrome": "Monochrome"
                })[v] ?? v
                onPicked: v => Settings.values.colorStyle = v
            }
        }

        SettingRow {
            title: "Contrast"

            Stepper {
                label: "Contrast"
                values: [-0.5, 0, 0.5, 1]
                value: Settings.values.colorContrast
                format: v => ({ "-0.5": "Lower", "0": "Standard", "0.5": "Higher", "1": "Highest" })[String(v)]
                onPicked: v => Settings.values.colorContrast = v
            }
        }

        SettingRow {
            title: "Accent color"
            subtitle: Settings.values.accentColor ? "Instead of the wallpaper's; the wallpaper still shows"
                                                  : "Taken from the wallpaper"

            Row {
                spacing: Theme.spacing.s

                // The chosen color.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Settings.values.accentColor !== ""
                    width: Theme.icon.normal
                    height: width
                    radius: width / 2
                    color: Settings.values.accentColor || "transparent"
                }

                Stepper {
                    label: "Accent color"
                    values: ["", "#6750a4", "#1e66f5", "#00897b", "#43a047", "#fb8c00", "#e53935", "#d81b60"]
                    value: Settings.values.accentColor
                    format: v => ({
                        "": "Wallpaper", "#6750a4": "Purple", "#1e66f5": "Blue", "#00897b": "Teal",
                        "#43a047": "Green", "#fb8c00": "Orange", "#e53935": "Red", "#d81b60": "Pink"
                    })[v] ?? v
                    onPicked: v => Settings.values.accentColor = v
                }
            }
        }
    }

    SettingGroup {
        title: "Size"

        SettingRow {
            title: "Shell size"
            subtitle: "The island, menus, dock, launcher and Settings"

            Stepper {
                label: "Shell size"
                values: ThemeScale.sizes
                value: Theme.scale
                format: v => Math.round(v * 100) + " %"
                onPicked: v => Settings.values.uiScale = v
            }
        }

        SettingRow {
            title: "Text size"
            subtitle: "On top of the shell's size"

            Stepper {
                label: "Text size"
                values: ThemeScale.textSizes
                value: Theme.textScale
                format: v => Math.round(v * 100) + " %"
                onPicked: v => Settings.values.textScale = v
            }
        }

        SettingRow {
            title: "Corners"
            subtitle: "The shell's own; windows have theirs under Windows"

            Stepper {
                label: "Corners"
                values: ThemeScale.corners
                value: Theme.cornerScale
                format: v => ({ 0: "Square", 0.5: "Less round", 1: "Round", 1.5: "Rounder" })[v] ?? v
                onPicked: v => Settings.values.cornerScale = v
            }
        }

        SettingRow {
            title: "Launcher"
            subtitle: "Its width, and how many results show before the list scrolls"

            Row {
                spacing: Theme.spacing.s

                Stepper {
                    label: "Launcher width"
                    values: ThemeScale.launcherWidths
                    value: ThemeScale.pick(Settings.values.launcherWidth, ThemeScale.launcherWidths, 560)
                    format: v => ({ 480: "Narrow", 560: "Normal", 640: "Wide", 720: "Wider" })[v] ?? v
                    onPicked: v => Settings.values.launcherWidth = v
                }

                Stepper {
                    label: "Launcher rows"
                    values: ThemeScale.launcherRows
                    value: Theme.launcher.rows
                    format: v => v + " rows"
                    onPicked: v => Settings.values.launcherRows = v
                }
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
            title: "Animation speed"
            subtitle: "The shell's and the windows' together"

            Stepper {
                label: "Animation speed"
                values: HyprlandConfig.animationSpeeds
                value: HyprlandConfig.animationSpeed(Settings.values.animationSpeed)
                format: v => v === 0 ? "Off" : v === 1 ? "Normal" : v < 1 ? "Slower (" + v + "×)" : "Faster (" + v + "×)"
                onPicked: v => Settings.values.animationSpeed = v
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

    // Fonts: a short list of good ones, only those installed (Qt.fontFamilies()).
    readonly property var installedFonts: Qt.fontFamilies()

    SettingGroup {
        title: "Fonts"

        SettingRow {
            title: "Text"
            subtitle: "The shell's menus, island and Settings"

            Stepper {
                label: "Text font"
                values: ["Inter", "Adwaita Sans", "Cantarell", "Noto Sans", "Open Sans", "Roboto",
                         "IBM Plex Sans", "Fira Sans", "Ubuntu", "DejaVu Sans"].filter(f => page.installedFonts.includes(f))
                valueWidth: Theme.settings.stepperWide
                value: Theme.font.sans
                onPicked: v => Settings.values.fontSans = v === "Inter" ? "" : v
            }
        }

        SettingRow {
            title: "Monospaced"
            subtitle: "Error messages and code"

            Stepper {
                label: "Monospaced font"
                values: ["MesloLGS Nerd Font", "JetBrainsMono Nerd Font", "JetBrains Mono", "Fira Code",
                         "Adwaita Mono", "Noto Sans Mono", "DejaVu Sans Mono", "Source Code Pro", "Hack"].filter(f => page.installedFonts.includes(f))
                valueWidth: Theme.settings.stepperWide
                value: Theme.font.mono
                onPicked: v => Settings.values.fontMono = v === "MesloLGS Nerd Font" ? "" : v
            }
        }
    }

    // Icon themes: the installed ones, their dark and light versions as one (matugen's
    // wallpaper.sh picks the version for the mode).
    property var iconThemes: ["Colloid"]

    Process {
        command: ["sh", "-c", `for d in /usr/share/icons/*/index.theme "$HOME"/.local/share/icons/*/index.theme; do
            [ -f "$d" ] || continue
            n=$(basename "$(dirname "$d")")
            case "$n" in *-Dark|*-Light|*-dark|hicolor|locolor|default|AdwaitaLegacy) continue ;; esac
            grep -q "^Directories=" "$d" && echo "$n"
        done`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.iconThemes = text.split("\n").filter(n => n !== "").sort((a, b) => a.localeCompare(b))
        }
    }

    SettingGroup {
        title: "Icons"

        SettingRow {
            title: "Icon theme"
            subtitle: "Apps' icons, in Colloid's folder color or another theme; its dark or light version follows the mode"

            Stepper {
                label: "Icon theme"
                values: page.iconThemes
                valueWidth: Theme.settings.stepperWide
                value: Settings.values.iconTheme
                format: v => v.replace(/^Colloid-?/, "Colloid ").trim()
                onPicked: v => Settings.values.iconTheme = v
            }
        }

        SettingRow {
            title: "The shell's own icons change after it restarts"
            subtitle: "The dock, launcher and island read the icon theme when the shell starts. Restarting clears the notification list."

            TextButton {
                text: "Restart the shell"
                onClicked: Quickshell.execDetached(["sh", "-c", "pkill -x qs; sleep 1; exec \"$HOME\"/.config/hypr/shell.sh"])
            }
        }
    }

    SettingGroup {
        title: "Workspaces"

        SettingRow {
            title: "Workspace dots"
            subtitle: Theme.workspace.minimum === 0 ? "Only the workspaces you use (and the one you're on)"
                    : "Always " + Theme.workspace.minimum + ", more when you use a higher one"

            Stepper {
                label: "Workspace dots"
                values: ThemeScale.workspaceDots
                value: Theme.workspace.minimum
                format: v => v === 0 ? "In use" : String(v)
                onPicked: v => Settings.values.workspaceDots = v
            }
        }
    }

    // The island's status icons, each on or off (bar/StatusIcons.qml). The privacy ones
    // (recording, microphone, camera, screen sharing) always show, so they aren't listed.
    SettingGroup {
        title: "Status icons"

        Repeater {
            model: [
                { key: "wifi", title: "Wi-Fi or cable" },
                { key: "bluetooth", title: "Bluetooth device connected" },
                { key: "vpn", title: "VPN connected" },
                { key: "airplane", title: "Airplane mode" },
                { key: "timer", title: "Timer running" },
                { key: "updates", title: "Updates waiting" },
                { key: "muted", title: "Sound muted" },
                { key: "battery", title: "Battery" }
            ]

            SettingRow {
                id: iconRow

                required property var modelData
                readonly property var hidden: Array.from(Settings.values.hiddenStatusIcons ?? [])

                title: modelData.title

                Switch {
                    label: "Show " + iconRow.modelData.title
                    checked: !iconRow.hidden.includes(iconRow.modelData.key)
                    onToggled: Settings.values.hiddenStatusIcons = checked
                        ? [...iconRow.hidden, iconRow.modelData.key]
                        : iconRow.hidden.filter(k => k !== iconRow.modelData.key)
                }
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

        SettingRow {
            title: "Opening and closing"
            subtitle: "How windows appear and go"

            Stepper {
                label: "Window animation"
                values: Object.keys(HyprlandConfig.windowStyles)
                valueWidth: Theme.settings.stepperWide
                value: HyprlandConfig.style(Settings.values.windowAnimation, HyprlandConfig.windowStyles)
                format: v => ({ popin: "Pop in", slide: "Slide", gnomed: "Grow" })[v]
                onPicked: v => Settings.values.windowAnimation = v
            }
        }

        SettingRow {
            title: "Switching workspaces"

            Stepper {
                label: "Workspace animation"
                values: Object.keys(HyprlandConfig.workspaceStyles)
                valueWidth: Theme.settings.stepperWide
                value: HyprlandConfig.style(Settings.values.workspaceAnimation, HyprlandConfig.workspaceStyles)
                format: v => ({ fade: "Fade", slide: "Slide", slidevert: "Slide up", slidefade: "Slide and fade" })[v]
                onPicked: v => Settings.values.workspaceAnimation = v
            }
        }

        SettingRow {
            title: "Turning border"
            subtitle: "The border's colors go round; redraws the screen all the time, so it costs battery"

            Switch {
                label: "Turning border"
                checked: Settings.values.borderSpin
                onToggled: Settings.values.borderSpin = !checked
            }
        }

        SettingRow {
            title: "Glow"
            subtitle: "A soft glow in your accent color inside the focused window's edge"

            Switch {
                label: "Window glow"
                checked: Settings.values.windowGlow
                onToggled: Settings.values.windowGlow = !checked
            }
        }

        SettingRow {
            title: "Floating and pinned windows stand out"
            subtitle: "A floating window's border in another of your colors, a pinned one's (picture-in-picture) in a third"

            Switch {
                label: "Own border colors for floating and pinned windows"
                checked: Settings.values.windowKindBorders
                onToggled: Settings.values.windowKindBorders = !checked
            }
        }
    }
}
