import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "../services/Schedule.js" as Schedule
import "DisplayModes.js" as DisplayModes
import "../theme/ThemeScale.js" as ThemeScale

// Display: the shell's size and its text's (the same settings as the desktop editor's Size and
// text tab) and the launcher's, each screen's resolution and refresh rate, scale, rotation and variable refresh
// rate; night light (on/off, how warm, and an optional daily schedule).
//
// A screen change is tried live (`hyprctl eval` of an `hl.monitor` call) and only saved when
// "Keep" is clicked; otherwise it goes back after 15 s, so a mode the screen can't show undoes
// itself. Saved setups go to shell-settings.lua (HyprlandConfig.js) and override monitors.lua.
Column {
    id: root

    property var monitors: [] // `hyprctl monitors -j`, re-read each time the page is shown
    // The change being tried: { output, setup, previous }, or null.
    property var trial: null
    property int secondsLeft

    function apply(output: string, setup: var): void {
        const lua = DisplayModes.lua(output, setup);
        if (lua !== "")
            Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    // Further changes to the same screen keep the setup from before the first one to go back to.
    function tryOut(output: string, current: var, change: var): void {
        const setup = Object.assign({}, current, change);
        trial = { output: output, setup: setup, previous: trial ? trial.previous : current };
        secondsLeft = 15;
        countdown.restart();
        apply(output, setup);
    }

    function keep(): void {
        countdown.stop();
        // Under the monitor's own key (its description), so it gets this back on any port.
        const monitor = monitors.find(m => m.name === trial.output);
        const key = monitor ? DisplayModes.key(monitor, monitors) : trial.output;
        Settings.values.monitors = Object.assign({}, Settings.values.monitors, { [key]: trial.setup });
        trial = null;
        read.running = true;
    }

    function revert(): void {
        countdown.stop();
        apply(trial.output, trial.previous);
        trial = null;
        read.running = true;
    }

    spacing: Theme.spacing.l
    onVisibleChanged: {
        if (visible)
            read.running = true;
    }
    Component.onCompleted: read.running = true
    // A screen plugged in or out while the page is kept (the launcher keeps it): read again.
    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            read.running = true;
        }
    }
    // Closing the settings window mid-try goes back rather than keeping an unconfirmed mode.
    Component.onDestruction: {
        if (trial)
            revert();
    }

    Process {
        id: read
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.monitors = JSON.parse(text)
        }
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: {
            root.secondsLeft--;
            if (root.secondsLeft <= 0)
                root.revert();
        }
    }

    // How big the shell is, beside the screens' own scale (user's find, 2026-11-05: the size lived
    // only in the desktop editor, apart from the scale here). The shell only, so it can go
    // below 100 %: the same 1080p is about 1.5 times bigger on a 24" monitor than on a 16" laptop.
    SettingGroup {
        title: "Size"

        Repeater {
            model: [
                { key: "uiScale", title: "Shell", subtitle: "The island, menus, launcher, dock and widgets", values: ThemeScale.sizes, current: Theme.scale },
                { key: "textScale", title: "Text", subtitle: "The shell's text, on top of its size", values: ThemeScale.textSizes, current: Theme.textScale }
            ]

            SettingRow {
                id: sizeRow

                required property var modelData

                title: modelData.title
                subtitle: modelData.subtitle

                Stepper {
                    label: sizeRow.title + " size"
                    values: sizeRow.modelData.values
                    value: sizeRow.modelData.current
                    format: v => Math.round(v * 100) + " %"
                    onPicked: v => Settings.values[sizeRow.modelData.key] = v
                }
            }
        }

        SettingRow {
            title: "Launcher width"

            Stepper {
                label: "Launcher width"
                values: ThemeScale.launcherWidths
                value: ThemeScale.pick(Settings.values.launcherWidth, ThemeScale.launcherWidths, 560)
                format: v => ({ 480: "Narrow", 560: "Normal", 640: "Wide", 720: "Wider" })[v] ?? v
                onPicked: v => Settings.values.launcherWidth = v
            }
        }

        SettingRow {
            title: "Launcher rows"
            subtitle: "How many results show before the list scrolls"

            Stepper {
                label: "Launcher rows"
                values: ThemeScale.launcherRows
                value: Theme.launcher.rows
                format: v => v + " rows"
                onPicked: v => Settings.values.launcherRows = v
            }
        }
    }

    // With several screens: which is the main one (the dock, the desktop widgets) and where the
    // dock goes (services/Screens.qml).
    SettingGroup {
        visible: Screens.several
        title: "Screens"

        SettingRow {
            title: "Main screen"
            subtitle: "The desktop widgets and the dock show here"

            Stepper {
                label: "Main screen"
                values: Quickshell.screens.map(s => s.name)
                value: Screens.main?.name ?? ""
                format: v => root.screenName(v)
                onPicked: v => Settings.values.mainScreen = v
            }
        }

        SettingRow {
            title: "Workspaces per screen"
            subtitle: "The main screen 1-5, the next 6-10. Super + Shift + Alt + Left or Right moves a window to the screen that way"

            Switch {
                label: "Workspaces per screen"
                checked: Settings.values.workspacesPerScreen !== false
                onToggled: Settings.values.workspacesPerScreen = !checked
            }
        }

        SettingRow {
            title: "A wallpaper per screen"
            subtitle: "Off: the same picture on every screen, each filled without stretching. On: pick one for each screen in the wallpaper strip (Super + Shift + W) on that screen; the main screen's makes the colors"

            Switch {
                label: "A wallpaper per screen"
                checked: Settings.values.wallpaperPerScreen === true
                onToggled: Settings.values.wallpaperPerScreen = !checked
            }
        }

        SettingRow {
            title: "Dock on every screen"
            subtitle: "Off: only on the main screen"

            Switch {
                label: "Dock on every screen"
                checked: Settings.values.dockEverywhere === true
                onToggled: Settings.values.dockEverywhere = !checked
            }
        }
    }

    // The arrangement, with several screens: drag them where they sit on your desk.
    SettingGroup {
        visible: root.monitors.length > 1
        title: "Arrangement"

        ScreenArrangement {
            width: parent.width
            monitors: root.monitors
            nameOf: output => root.screenName(output)
            onArranged: positions => {
                const layouts = Object.assign({}, Settings.values.screenLayouts);
                layouts[DisplayModes.setKey(root.monitors)] = positions;
                Settings.values.screenLayouts = layouts;
                rereadSoon.restart();
            }
        }
    }

    Timer {
        id: rereadSoon
        interval: 800 // after Hyprland has the new places
        onTriggered: read.running = true
    }

    // "Built-in screen", or the monitor's own name ("Dell U2723QE"), for an output.
    function screenName(output: string): string {
        if (/^(eDP|LVDS)/.test(output))
            return "Built-in screen";
        const m = monitors.find(m => m.name === output);
        return m && (m.make || m.model) ? [m.make, m.model].filter(s => s).join(" ") : output;
    }

    SettingGroup {
        visible: root.trial !== null
        title: "Keep these display settings?"

        SettingRow {
            title: "Going back in " + root.secondsLeft + " s"
            subtitle: "If the screen looks wrong, wait and it changes back"

            Row {
                spacing: Theme.spacing.s

                TextButton {
                    text: "Go back"
                    onClicked: root.revert()
                }

                TextButton {
                    text: "Keep"
                    filled: true
                    onClicked: root.keep()
                }
            }
        }
    }

    Repeater {
        model: root.monitors

        SettingGroup {
            id: screen

            required property var modelData
            readonly property string output: modelData.name
            readonly property bool trying: root.trial?.output === output
            // What the steppers show: the change being tried, else what the screen runs now.
            readonly property var setup: trying ? root.trial.setup
                : DisplayModes.current(modelData, DisplayModes.savedFor(Settings.values.monitors, modelData, root.monitors)?.vrr)
            readonly property var modes: DisplayModes.modes(modelData.availableModes).reverse()

            title: output.startsWith("eDP") ? "Built-in screen" : (modelData.description || output)
            // One screen at a time: another one waits until this try is kept or undone.
            enabled: root.trial === null || trying

            SettingRow {
                title: "Resolution and refresh rate"

                Stepper {
                    label: "Resolution and refresh rate"
                    valueWidth: Theme.settings.stepperWide
                    values: screen.modes.map(m => m.mode)
                    value: screen.setup.mode
                    format: v => screen.modes.find(m => m.mode === v)?.label ?? v
                    onPicked: v => root.tryOut(screen.output, screen.setup, { mode: v })
                }
            }

            SettingRow {
                title: "Scale"
                subtitle: "Everything on this screen, apps too; Hyprland rounds to the nearest size that fits. For the shell alone, see Size above"

                Stepper {
                    label: "Scale"
                    values: [1, 1.25, 1.5, 1.75, 2]
                    value: screen.setup.scale
                    format: v => Math.round(v * 100) + " %"
                    onPicked: v => root.tryOut(screen.output, screen.setup, { scale: v })
                }
            }

            SettingRow {
                title: "Rotation"

                Stepper {
                    label: "Rotation"
                    values: [0, 1, 2, 3] // Hyprland's transforms without the flipped ones
                    wrap: true
                    value: screen.setup.transform
                    format: v => ["Normal", "90°", "180°", "270°"][v] ?? "Flipped"
                    onPicked: v => root.tryOut(screen.output, screen.setup, { transform: v })
                }
            }

            SettingRow {
                title: "Variable refresh rate"
                subtitle: "Smoother games on screens that support it"

                Stepper {
                    label: "Variable refresh rate"
                    values: [0, 2, 1]
                    value: screen.setup.vrr
                    format: v => ({ 0: "Off", 1: "Always", 2: "Fullscreen" })[v] ?? "Off"
                    onPicked: v => root.tryOut(screen.output, screen.setup, { vrr: v })
                }
            }
        }
    }

    SettingGroup {
        SettingRow {
            title: "Night light"
            subtitle: "Warmer colors, easier on the eyes in the evening"

            Switch {
                label: "Night light"
                checked: NightLight.on
                onToggled: NightLight.toggle()
            }
        }

        SettingRow {
            title: "Warmth"
            subtitle: "Lower is warmer"

            Stepper {
                label: "Warmth"
                values: Array.from({ length: 15 }, (_, i) => 2500 + i * 250)
                value: Settings.values.nightLightTemperature
                format: v => v + " K"
                onPicked: v => Settings.values.nightLightTemperature = v
            }
        }
    }

    SettingGroup {
        title: "Schedule"

        SettingRow {
            title: "Turn on automatically"
            subtitle: "Switching it by hand lasts until the next start or end time"

            Switch {
                label: "Night light schedule"
                checked: Settings.values.nightLightScheduled
                onToggled: Settings.values.nightLightScheduled = !checked
            }
        }

        SettingRow {
            title: "From"
            enabled: Settings.values.nightLightScheduled

            Stepper {
                label: "Night light from"
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values.nightLightStart
                format: Schedule.format
                onPicked: v => Settings.values.nightLightStart = v
            }
        }

        SettingRow {
            title: "Until"
            enabled: Settings.values.nightLightScheduled

            Stepper {
                label: "Night light until"
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values.nightLightEnd
                format: Schedule.format
                onPicked: v => Settings.values.nightLightEnd = v
            }
        }
    }
}
