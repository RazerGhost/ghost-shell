import QtQuick
import Quickshell
import Quickshell.Io
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets
import "XkbLayouts.js" as XkbLayouts
import "HyprlandConfig.js" as HyprlandConfig

// Keyboard and touchpad: the keyboard layout, touchpad scrolling and
// tapping, pointer speed. Applied through Hyprland (HyprlandSettings.qml).
Column {
    id: root

    // Every layout XKB knows, by name.
    readonly property var layouts: XkbLayouts.layouts(baseLst.text())
    // The chosen one first; while searching, the matches.
    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        if (q !== "")
            return layouts.filter(l => l.name.toLowerCase().includes(q) || l.code === q);
        const chosen = layouts.filter(l => l.code === Settings.values.keyboardLayout);
        return chosen.concat(layouts.filter(l => l.code !== Settings.values.keyboardLayout));
    }

    spacing: Theme.spacing.l

    FileView {
        id: baseLst
        path: "/usr/share/X11/xkb/rules/base.lst"
        blockLoading: true
    }

    SettingGroup {
        title: "Keyboard layout"

        Item {
            width: parent.width
            height: search.height + Theme.spacing.m * 2

            SearchField {
                id: search
                x: Theme.spacing.m
                y: Theme.spacing.m
                width: parent.width - Theme.spacing.m * 2
                placeholder: "Search layouts (" + (root.layouts.find(l => l.code === Settings.values.keyboardLayout)?.name
                                                  ?? Settings.values.keyboardLayout) + ")"
            }
        }

        ListView {
            x: Theme.spacing.s
            width: parent.width - Theme.spacing.s * 2
            height: Theme.list.rowHeight * 5
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel { values: root.shown }

            Accessible.role: Accessible.List
            Accessible.name: "Keyboard layouts"

            delegate: ListRow {
                required property var modelData
                readonly property bool chosen: modelData.code === Settings.values.keyboardLayout

                width: ListView.view.width
                icon: "keyboard"
                title: modelData.name
                subtitle: modelData.code
                highlighted: chosen
                trailingIcon: chosen ? "check" : ""
                onActivated: Settings.values.keyboardLayout = modelData.code

                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: chosen
            }
        }
    }

    SettingGroup {
        title: "Touchpad and mouse"

        SettingRow {
            title: "Natural scrolling"
            subtitle: "Content moves with your fingers, like a phone (touchpad)"

            Switch {
                label: "Natural scrolling"
                checked: Settings.values.naturalScroll
                onToggled: Settings.values.naturalScroll = !checked
            }
        }

        SettingRow {
            title: "Tap to click"
            subtitle: "A tap on the touchpad clicks"

            Switch {
                label: "Tap to click"
                checked: Settings.values.tapToClick
                onToggled: Settings.values.tapToClick = !checked
            }
        }

        SettingRow {
            title: "Touchpad off while a mouse is connected"
            subtitle: "Back on by itself when the mouse is gone"

            Switch {
                label: "Touchpad off while a mouse is connected"
                checked: Settings.values.touchpadOffWithMouse
                onToggled: Settings.values.touchpadOffWithMouse = !checked
            }
        }

        SettingRow {
            title: "Pointer speed"
            subtitle: "Mouse and touchpad"

            Stepper {
                label: "Pointer speed"
                values: Array.from({ length: 21 }, (_, i) => (i - 10) / 10)
                value: Settings.values.pointerSpeed
                format: v => v === 0 ? "Normal" : (v > 0 ? "+" : "") + Math.round(v * 100) + " %"
                onPicked: v => Settings.values.pointerSpeed = v
            }
        }
    }

    SettingGroup {
        title: "Pointer"

        SettingRow {
            title: "Look"
            subtitle: "The installed cursor themes"

            Stepper {
                label: "Cursor theme"
                values: root.cursorThemes
                valueWidth: Theme.settings.stepperWide
                value: HyprlandConfig.cursorTheme(Settings.values.cursorTheme)
                onPicked: v => Settings.values.cursorTheme = v === "Adwaita" ? "" : v
            }
        }

        SettingRow {
            title: "Size"

            Stepper {
                label: "Cursor size"
                values: HyprlandConfig.cursorSizes
                value: HyprlandConfig.cursorSize(Settings.values.cursorSize)
                format: v => v + " px"
                onPicked: v => Settings.values.cursorSize = v
            }
        }

        SettingRow {
            title: "Hide while typing"
            subtitle: "Back when the pointer moves"

            Switch {
                label: "Hide the pointer while typing"
                checked: Settings.values.cursorHideTyping
                onToggled: Settings.values.cursorHideTyping = !checked
            }
        }

        SettingRow {
            title: "Hide when still"

            Stepper {
                label: "Hide the pointer when it's still"
                values: HyprlandConfig.cursorHideTimes
                value: HyprlandConfig.cursorHideAfter(Settings.values.cursorHideAfter)
                format: v => v === 0 ? "Never" : "After " + v + " s"
                onPicked: v => Settings.values.cursorHideAfter = v
            }
        }
    }

    // Cursor themes: icon theme folders with a cursors folder, system-wide or your own.
    property var cursorThemes: ["Adwaita"]

    Process {
        command: ["sh", "-c", `for d in /usr/share/icons/*/cursors "$HOME"/.local/share/icons/*/cursors "$HOME"/.icons/*/cursors; do
            [ -d "$d" ] && basename "$(dirname "$d")"; done | sort -u`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\n").filter(n => n !== "" && HyprlandConfig.cursorTheme(n) === n);
                root.cursorThemes = found.length ? found : ["Adwaita"];
            }
        }
    }
}
