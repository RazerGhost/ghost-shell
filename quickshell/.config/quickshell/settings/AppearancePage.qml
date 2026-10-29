import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "../theme/ThemeScale.js" as ThemeScale

// Appearance: what isn't edited on the desktop itself (the desktop editor, customize/, has the
// wallpaper, colors, widgets, the panels' style, sizes and fonts): the wallpaper folder and
// slideshow, and the launcher's size. The other editors have the rest: the dock and island
// (workspace dots, status icons), the windows (border, corners, gaps, animations).
Column {
    id: page

    spacing: Theme.spacing.l

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
}
