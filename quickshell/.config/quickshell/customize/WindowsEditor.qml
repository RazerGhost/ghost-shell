import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../settings/HyprlandConfig.js" as HyprlandConfig
import "Presets.js" as Presets

// The windows editor: your windows' borders, corners, gaps and motion, shown on the windows
// themselves (it stays on your workspace; Hyprland applies each change in a moment). The
// animations have Play buttons: a sample window opens and closes, or the workspace switches
// away and back. Cancel writes the earlier settings back. Opened from Settings -> Windows and
// the launcher (Customize.qml).
Scope {
    id: root

    property var saved: ({})

    // A row of steps plus the current value when it isn't one (set by hand), so it shows.
    function withCurrent(steps: var, value: var): var {
        return steps.includes(value) ? steps : [...steps, value].sort((a, b) => a - b);
    }

    function open(): void {
        if (editor.active)
            return;
        saved = Presets.snapshot(Settings.values, Presets.windowsKeys);
        editor.active = true;
    }

    function close(): void {
        if (!editor.active)
            return;
        editor.active = false;
        sample.active = false;
    }

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        close();
    }

    // Long enough for the slowest animation to finish (at half speed).
    readonly property int playTime: Math.round(1200 / Math.max(HyprlandConfig.animationSpeed(Settings.values.animationSpeed), 0.5))

    // Play: the sample window opens, stays a moment, closes (it floats: rules.lua).
    function playWindow(): void {
        sample.active = true;
        sampleClose.restart();
    }

    // Play: the workspace switches to an empty one and back.
    function playWorkspace(): void {
        Editing.toEmptyWorkspace();
        workspaceBack.restart();
    }

    Timer {
        id: sampleClose
        interval: root.playTime
        onTriggered: sample.active = false
    }

    Timer {
        id: workspaceBack
        interval: root.playTime
        onTriggered: Editing.back()
    }

    LazyLoader {
        id: sample

        FloatingWindow {
            title: "Animation sample"
            implicitWidth: Theme.editor.sample
            implicitHeight: Math.round(Theme.editor.sample * 0.6)
            color: Colors.m3surfaceContainer

            Text {
                anchors.centerIn: parent
                text: "Animation sample"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.large
            }
        }
    }

    LazyLoader {
        id: editor

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            mask: Region {
                item: chrome.sheet
                Region { item: chrome.cancelPill }
                Region { item: chrome.donePill }
            }

            BackgroundEffect.blurRegion: Region {
                item: chrome.sheet
                radius: chrome.sheet.radius
                Region { item: chrome.cancelPill; radius: Theme.radius.full }
                Region { item: chrome.donePill; radius: Theme.radius.full }
            }

            EditorChrome {
                id: chrome
                tabs: [{ value: "borders", label: "Borders" }, { value: "space", label: "Space" }, { value: "motion", label: "Motion" }]
                glass: true
                status: Hyprland.focusedWorkspace?.toplevels.values.length > 0 ? "" : "Open a window to see these on it"
                onCancelled: root.cancel()
                onFinished: root.close()

                // Borders: width, corners and the extras.
                Column {
                    width: parent.width
                    visible: chrome.tab === "borders"

                    SettingRow {
                        title: "Border"
                        subtitle: "In your wallpaper's colors"

                        Segmented {
                            options: root.withCurrent([0, 1, 2, 3, 4], Settings.values.borderSize).map(v => ({ value: v, label: v === 0 ? "None" : v + " px" }))
                            current: Settings.values.borderSize
                            onPicked: v => Settings.values.borderSize = v
                        }
                    }

                    SettingRow {
                        title: "Corners"

                        Segmented {
                            options: root.withCurrent([0, 6, 10, 14, 20], Settings.values.rounding).map(v => ({ value: v, label: ({ 0: "Square", 6: "Less", 10: "Round", 14: "More", 20: "Most" })[v] ?? v + " px" }))
                            current: Settings.values.rounding
                            onPicked: v => Settings.values.rounding = v
                        }
                    }

                    Repeater {
                        model: [
                            { key: "borderSpin", title: "Turning border", subtitle: "Its colors go round; redraws all the time, so it costs battery" },
                            { key: "windowGlow", title: "Glow", subtitle: "A soft glow in your accent inside the focused window's edge" },
                            { key: "windowKindBorders", title: "Floating and pinned windows stand out", subtitle: "Their borders in other colors of yours" }
                        ]

                        SettingRow {
                            id: extraRow
                            required property var modelData
                            title: modelData.title
                            subtitle: modelData.subtitle

                            Switch {
                                label: extraRow.modelData.title
                                checked: Settings.values[extraRow.modelData.key]
                                onToggled: Settings.values[extraRow.modelData.key] = !checked
                            }
                        }
                    }
                }

                // Space: the gaps between tiled windows and at the screen's edges.
                Column {
                    width: parent.width
                    visible: chrome.tab === "space"

                    SettingRow {
                        title: "Between windows"

                        Segmented {
                            options: root.withCurrent([0, 3, 5, 8, 12], Settings.values.gapsIn).map(v => ({ value: v, label: v === 0 ? "None" : v + " px" }))
                            current: Settings.values.gapsIn
                            onPicked: v => Settings.values.gapsIn = v
                        }
                    }

                    SettingRow {
                        title: "At the screen's edges"

                        Segmented {
                            options: root.withCurrent([0, 8, 14, 20, 30], Settings.values.gapsOut).map(v => ({ value: v, label: v === 0 ? "None" : v + " px" }))
                            current: Settings.values.gapsOut
                            onPicked: v => Settings.values.gapsOut = v
                        }
                    }
                }

                // Motion: speed and styles, each with Play; wobbly windows.
                Column {
                    width: parent.width
                    visible: chrome.tab === "motion"

                    SettingRow {
                        title: "Speed"
                        subtitle: "The shell's and the windows' together"

                        Segmented {
                            options: HyprlandConfig.animationSpeeds.map(v => ({ value: v, label: v === 0 ? "Off" : v === 1 ? "Normal" : v + "×" }))
                            current: HyprlandConfig.animationSpeed(Settings.values.animationSpeed)
                            onPicked: v => Settings.values.animationSpeed = v
                        }
                    }

                    SettingRow {
                        title: "Opening and closing"

                        Row {
                            spacing: Theme.spacing.s

                            Segmented {
                                options: Object.keys(HyprlandConfig.windowStyles).map(v => ({ value: v, label: ({ popin: "Pop in", slide: "Slide", gnomed: "Grow" })[v] }))
                                current: HyprlandConfig.style(Settings.values.windowAnimation, HyprlandConfig.windowStyles)
                                onPicked: v => Settings.values.windowAnimation = v
                            }

                            IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "play_arrow"
                                label: "Play: open and close a window"
                                onClicked: root.playWindow()
                            }
                        }
                    }

                    SettingRow {
                        title: "Switching workspaces"

                        Row {
                            spacing: Theme.spacing.s

                            Segmented {
                                options: Object.keys(HyprlandConfig.workspaceStyles).map(v => ({ value: v, label: ({ fade: "Fade", slide: "Slide", slidevert: "Up", slidefade: "Slide fade" })[v] }))
                                current: HyprlandConfig.style(Settings.values.workspaceAnimation, HyprlandConfig.workspaceStyles)
                                onPicked: v => Settings.values.workspaceAnimation = v
                            }

                            IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "play_arrow"
                                label: "Play: switch away and back"
                                onClicked: root.playWorkspace()
                            }
                        }
                    }

                    SettingRow {
                        title: "Wobbly windows"
                        subtitle: "They wobble like jelly while you move or resize them"

                        Switch {
                            label: "Wobbly windows"
                            checked: Settings.values.wobble
                            onToggled: Settings.values.wobble = !checked
                        }
                    }
                }
            }
        }
    }
}
