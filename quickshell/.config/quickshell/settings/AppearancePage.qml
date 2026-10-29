import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "HyprlandConfig.js" as HyprlandConfig
import "../theme/ThemeScale.js" as ThemeScale

// Appearance: what isn't edited on the desktop itself (the desktop editor, customize/, has the
// wallpaper, colors, widgets, the panels' style, sizes and fonts): the wallpaper folder and
// slideshow, the launcher's size, animation speed, the workspace dots, status icons, and the
// windows' border and corners (applied through Hyprland, HyprlandSettings.qml).
Column {
    id: page

    spacing: Theme.spacing.l

    readonly property var pixels: v => v === 0 ? "None" : v + " px"

    SettingGroup {
        SettingRow {
            title: "Customize the desktop"
            subtitle: "Wallpaper, colors, widgets, style, size and fonts, on the desktop itself"

            TextButton {
                text: "Customize"
                filled: true
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "customize", "desktop"])
            }
        }
    }

    SettingGroup {
        title: "Wallpaper"

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
    }

    SettingGroup {
        title: "Launcher"

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
        title: "Animation"

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
