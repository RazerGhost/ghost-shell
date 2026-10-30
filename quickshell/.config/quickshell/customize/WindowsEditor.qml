import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../settings/HyprlandConfig.js" as HyprlandConfig
import "Presets.js" as Presets

// The windows editor: the windows' borders, corners, gaps and motion, shown on two example
// windows it opens side by side on an empty workspace (user's choice: not relying on windows
// already being open; Done or Cancel close them and go back). Hyprland applies each change in
// a moment. The animations have Play buttons: a sample window opens and closes, or the
// workspace switches away and back. Cancel writes the earlier settings back. Opened from
// Settings -> Windows and the launcher (Customize.qml).
Scope {
    id: root

    property var saved: ({})

    // A row of steps plus the current value when it isn't one (set by hand), so it shows.
    function withCurrent(steps: var, value: var): var {
        return steps.includes(value) ? steps : [...steps, value].sort((a, b) => a - b);
    }

    function open(): void {
        if (editor.active || editorLater.running)
            return;
        saved = Presets.snapshot(Settings.values, Presets.windowsKeys);
        Editing.toEmptyWorkspace();
        Editing.hideDock = true;
        reservedRead.running = true;
        examples.active = true;
        editorLater.restart();
    }

    // The editor's window takes the keyboard, and Hyprland focuses no window while it's open:
    // focus the first example before, so its active border and glow show.
    Timer {
        id: editorLater
        interval: 400
        onTriggered: {
            Hyprland.dispatch(`hl.dsp.focus({ window = "title:^Example window$" })`);
            editor.active = true;
        }
    }

    function close(): void {
        if (!editor.active)
            return;
        editor.active = false;
        sample.active = false;
        examples.active = false;
        Editing.hideDock = false;
        Editing.back();
        // Drops the examples' workspace rule (made with hyprctl eval, not in any file).
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        close();
    }

    // The space bars already reserve on the screen ([left, top, right, bottom]: the island, an
    // always-shown dock), which the workspace's gaps stack on.
    property var reserved: [0, Theme.island.height, 0, 0]

    Process {
        id: reservedRead
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const monitor = JSON.parse(text).find(m => m.focused);
                    if (monitor?.reserved?.length === 4)
                        root.reserved = monitor.reserved;
                } catch (e) {
                    console.warn("WindowsEditor: can't read hyprctl monitors: " + e);
                }
            }
        }
    }

    // The examples tile inside the card: their workspace's gaps at the screen's edges are the
    // space around the card plus your own gaps (a workspace rule, applied live; reload drops it).
    function tileInto(card: rect, width: real, height: real): void {
        const id = Editing.emptyWorkspace;
        if (id <= 0 || card.width <= 0)
            return;
        const own = Number(Settings.values.gapsOut) || 0;
        const side = (space, bar) => Math.max(0, Math.round(space - bar + own));
        const gaps = `{ top = ${side(card.y, reserved[1])}, right = ${side(width - card.x - card.width, reserved[2])}, `
                   + `bottom = ${side(height - card.y - card.height, reserved[3])}, left = ${side(card.x, reserved[0])} }`;
        Quickshell.execDetached(["hyprctl", "eval", `hl.workspace_rule({ workspace = "${id}", gaps_out = ${gaps} })`]);
    }

    // Long enough for the slowest animation to finish (at half speed).
    readonly property int playTime: Math.round(1200 / Math.max(HyprlandConfig.animationSpeed(Settings.values.animationSpeed), 0.5))

    // Play: the sample window opens, stays a moment, closes (it floats: rules.lua).
    function playWindow(): void {
        sample.active = true;
        sampleClose.restart();
    }

    // Play: the workspace switches to an empty one and back to the examples' (its own trip:
    // Editing's is the way back to your workspace when the editor closes).
    property int playFrom: 0

    function playWorkspace(): void {
        playFrom = Hyprland.focusedWorkspace?.id ?? 0;
        const used = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0);
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${Math.max(0, ...used) + 1} })`);
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
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.playFrom} })`)
    }

    // The two example windows, tiled side by side on the empty workspace.
    LazyLoader {
        id: examples

        Scope {
            ExampleWindow {
                heading: "Example window"
            }

            ExampleWindow {
                heading: "Another window"
            }
        }
    }

    // Play's window: floats in the middle (rules.lua).
    LazyLoader {
        id: sample

        ExampleWindow {
            heading: "Animation sample"
        }
    }

    LazyLoader {
        id: editor

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // The desktop as a card (EditorChrome.card), the examples tiled inside it.
            Component.onCompleted: {
                Editing.card = chrome.card;
                Editing.cardScreen = screen?.name ?? "";
                tiling.restart();
            }
            Component.onDestruction: Editing.cardScreen = ""

            Connections {
                target: chrome
                function onCardChanged(): void {
                    Editing.card = chrome.card;
                    tiling.restart();
                }
            }

            Connections {
                target: Settings.values
                function onGapsOutChanged(): void {
                    tiling.restart();
                }
            }

            // Tab changes move the card a few times in a row: tile once.
            Timer {
                id: tiling
                interval: 150
                onTriggered: root.tileInto(chrome.card, window.width, window.height)
            }

            mask: Region {
                item: chrome.sheet
            }

            BackgroundEffect.blurRegion: Region {
                item: chrome.sheet
                radius: chrome.sheet.radius
            }

            EditorChrome {
                id: chrome
                tabs: [{ value: "borders", label: "Borders" }, { value: "space", label: "Space" }, { value: "motion", label: "Motion" }]
                glass: true
                cardTop: Theme.island.height + Theme.spacing.l * 2
                onCancelled: root.cancel()
                onFinished: root.close()

                // Borders: width, corners and the extras.
                SheetGrid {
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
                SheetGrid {
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
                SheetGrid {
                    visible: chrome.tab === "motion"

                    SettingRow {
                        title: "Speed"

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
