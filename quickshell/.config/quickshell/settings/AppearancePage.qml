import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// Appearance: the on-screen editors (customize/; the same four as the launcher's tiles), each
// for what's best picked by sight, and what isn't seen: the wallpaper folder and slideshow.
Column {
    id: page

    spacing: Theme.spacing.l

    // Every editor in one place (they were on Appearance and Windows, quick settings' on none).
    SettingGroup {
        title: "Customize"

        Repeater {
            model: [
                { editor: "desktop", title: "Desktop", subtitle: "Wallpaper, colors, widgets, the panels' style, fonts" },
                { editor: "windows", title: "Windows", subtitle: "Borders, corners, gaps and animations, shown on your windows" },
                { editor: "dock", title: "Dock and island", subtitle: "When the dock shows, its icons, the workspace dots, the island's clock and status icons" },
                { editor: "quick", title: "Quick settings", subtitle: "Which tiles and buttons it has, and their order" }
            ]

            SettingRow {
                id: editorRow

                required property var modelData

                title: modelData.title
                subtitle: modelData.subtitle

                TextButton {
                    text: "Customize"
                    filled: true
                    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "customize", editorRow.modelData.editor])
                }
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
            title: "More wallpapers"
            subtitle: "Anime art from wallhaven.cc, into your folder"

            TextButton {
                text: "Find wallpapers"
                onClicked: LauncherState.show("wallpapers")
            }
        }

        SettingRow {
            title: "Follow light and dark"
            subtitle: "A picture with a dark version (name-dark.jpg beside name.jpg) switches with the mode"

            Switch {
                label: "Wallpaper follows light and dark"
                checked: Settings.values.wallpaperFollowsMode
                onToggled: Settings.values.wallpaperFollowsMode = !checked
            }
        }
    }
}
