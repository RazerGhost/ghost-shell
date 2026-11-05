// The screens for quick settings' Display page: the laptop screen's refresh rate (saved like a
// mode kept in Settings -> Display), a lower rate while on battery (a setting), and a second
// screen's projection like Windows' Win+P (extend, duplicate, only one of them; not saved, so
// a shell restart or unplugging it brings the screens back as set up). What's in effect now is
// `setups`, which HyprlandSettings writes into shell-settings.lua (settings/DisplayModes.js).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import "../settings/DisplayModes.js" as DisplayModes
import "WorkspaceSlots.js" as WorkspaceSlots

Singleton {
    id: root

    // `hyprctl monitors all -j`, with screens that are off (the projection's).
    property var monitors: []
    readonly property var laptop: DisplayModes.laptop(monitors)
    readonly property var rates: DisplayModes.rates(laptop)
    readonly property bool hasSecondScreen: laptop !== null && monitors.length > 1
    // The laptop screen's rate as chosen (saved, else as it runs now); on battery with the
    // lower-rate setting the screen runs at `lowest` meanwhile.
    readonly property int chosenRate: {
        const saved = laptop ? Settings.values.monitors[laptop.name]?.mode : undefined;
        const match = String(saved ?? "").match(/@([\d.]+)$/);
        return match ? Math.round(Number(match[1])) : Math.round(laptop?.refreshRate ?? 0);
    }
    readonly property int lowest: rates.length > 0 ? rates[rates.length - 1] : 0
    readonly property bool lowered: UPower.onBattery && Settings.values.displayLowRefreshOnBattery === true
                                    && lowest > 0 && lowest < chosenRate
    // "extend", "mirror", "external" or "laptop" (DisplayModes.effective); only for this session.
    property string project: "extend"

    // The lid: closed with another screen on, the laptop's screen is off until it opens (logind
    // doesn't suspend then). Hyprland's lid switch binds tell it (`qs ipc call display lid`);
    // read from ACPI at start.
    property bool lidClosed: false

    // What shell-settings.lua gets. Not the battery's lower rate: that's set live (below), so
    // plugging in or out doesn't reload Hyprland's whole config.
    readonly property var setups: DisplayModes.effective(Settings.values.monitors, monitors, {
        project: project,
        layouts: Settings.values.screenLayouts,
        lidClosed: lidClosed
    })

    // The battery's lower rate, live (`hyprctl eval` of the laptop screen's hl.monitor), and the
    // chosen rate back when plugged in; again after a config reload, which writes the file's.
    function applyRate(): void {
        if (!laptop || rates.length < 2 || laptop.disabled)
            return;
        const base = setups[laptop.name] ?? DisplayModes.current(laptop, undefined);
        const lua = DisplayModes.lua(laptop.name, DisplayModes.withRate(base, lowered ? lowest : chosenRate));
        if (lua !== "")
            Quickshell.execDetached(["hyprctl", "eval", lua]);
    }
    onLoweredChanged: applyRate()

    IpcHandler {
        target: "display"

        // "closed" or "open" (hypr/binds.lua's lid switch binds).
        function lid(state: string): void {
            root.lidClosed = state === "closed";
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "cat /proc/acpi/button/lid/*/state 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.lidClosed = /closed/.test(text)
        }
    }

    // Workspaces per screen: the ones open already go to their screen too (a new main screen,
    // the setting turned on, a screen plugged in), after the rules are in.
    readonly property var workspaceHomes: Settings.values.workspacesPerScreen === false ? ({})
        : DisplayModes.workspaceHomes(Screens.main?.name ?? "", monitors)
    onWorkspaceHomesChanged: moveSoon.restart()
    Timer {
        id: moveSoon
        interval: 1500 // after shell-settings.lua is written and Hyprland has reloaded
        onTriggered: {
            // Ids through WorkspaceSlots.idOf: Quickshell reads them as -1 until the first switch.
            const open = Hyprland.workspaces.values.filter(w => WorkspaceSlots.idOf(w) > 0 && w.monitor)
                .map(w => ({ id: WorkspaceSlots.idOf(w), monitor: w.monitor.name }));
            for (const move of DisplayModes.workspaceMoves(root.workspaceHomes, open))
                Quickshell.execDetached(["hyprctl", "dispatch",
                    `hl.dsp.workspace.move({ workspace = "${move.workspace}", monitor = "${move.monitor}" })`]);
        }
    }

    // Workspaces per screen (Settings -> Display): Hyprland's rules for them while there are
    // several screens and the setting is on (DisplayModes.workspaceRules).
    readonly property string workspaceLua: Settings.values.workspacesPerScreen === false ? ""
        : DisplayModes.workspaceRules(Screens.main?.name ?? "", monitors).join("\n")

    function setRate(hz: int): void {
        if (!laptop)
            return;
        const saved = Settings.values.monitors[laptop.name] ?? DisplayModes.current(laptop, undefined);
        Settings.values.monitors = Object.assign({}, Settings.values.monitors,
                                                 { [laptop.name]: DisplayModes.withRate(saved, hz) });
    }

    Process {
        id: read
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {
                    console.warn("Display: hyprctl monitors gave no JSON");
                }
            }
        }
    }

    // A screen plugged in or out, or a reload (a new mode): look again. The second screen gone,
    // the projection goes back to extending.
    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved")
                    || event.name === "configreloaded")
                readSoon.restart();
            if (event.name === "configreloaded" && root.lowered)
                rateSoon.restart();
        }
    }
    onHasSecondScreenChanged: {
        if (!hasSecondScreen)
            project = "extend";
    }

    Timer {
        id: rateSoon
        interval: 300
        onTriggered: root.applyRate()
    }

    Timer {
        id: readSoon
        interval: 300
        onTriggered: read.running = true
    }
}
