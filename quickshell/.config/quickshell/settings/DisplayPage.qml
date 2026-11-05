import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "../services/Schedule.js" as Schedule
import "DisplayModes.js" as DisplayModes

// Display: each screen's resolution and refresh rate, scale, rotation and variable refresh rate;
// night light (on/off, how warm, and an optional daily schedule).
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
        Settings.values.monitors = Object.assign({}, Settings.values.monitors, { [trial.output]: trial.setup });
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
            title: "Dock on every screen"
            subtitle: "Off: only on the main screen"

            Switch {
                label: "Dock on every screen"
                checked: Settings.values.dockEverywhere === true
                onToggled: Settings.values.dockEverywhere = !checked
            }
        }
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
                : DisplayModes.current(modelData, Settings.values.monitors[output]?.vrr)
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
                subtitle: "Makes everything bigger; Hyprland rounds to the nearest size that fits"

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
