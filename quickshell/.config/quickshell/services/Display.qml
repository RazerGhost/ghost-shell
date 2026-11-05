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

    readonly property var setups: DisplayModes.effective(Settings.values.monitors, monitors, {
        onBattery: UPower.onBattery,
        lowOnBattery: Settings.values.displayLowRefreshOnBattery === true,
        project: project
    })

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
        }
    }
    onHasSecondScreenChanged: {
        if (!hasSecondScreen)
            project = "extend";
    }

    Timer {
        id: readSoon
        interval: 300
        onTriggered: read.running = true
    }
}
