// Turns the touchpad off while a mouse is connected (Settings -> Keyboard and mouse; off by
// default), and on again when it's gone. Hyprland sends no event when a mouse is plugged in, so
// udev's input events are watched while the setting is on (USB and Bluetooth mice both show up
// there), and Hyprland's devices are read a second after one (TouchpadDevices.js, tested); it
// polled every 3 s before (review 2026-10-29). The touchpads are switched with `hl.device`
// through `hyprctl eval`, only when that changes.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "TouchpadDevices.js" as TouchpadDevices

Singleton {
    id: root

    readonly property bool enabled: Settings.values.touchpadOffWithMouse
    // What the touchpads were last set to; null before the first time.
    property var applied: null

    function apply(touchpads: list<string>, on: bool): void {
        if (applied === on)
            return;
        applied = on;
        // Hyprland's device names are letters, digits and :._- ; anything else isn't sent.
        const safe = touchpads.filter(n => /^[A-Za-z0-9:._-]+$/.test(n));
        const lua = safe.map(n => `hl.device({ name = "${n}", enabled = ${on} })`).join("; ");
        if (lua !== "")
            Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    // Switched on: look now. Switched off: the touchpad back on.
    onEnabledChanged: check.start()
    Component.onCompleted: {
        if (enabled)
            checkSoon.restart();
    }

    // A device plugged in or out: Hyprland takes a moment to list it, and one device sends
    // several events, so look once, a second after the last.
    Timer {
        id: checkSoon
        interval: 1000
        onTriggered: check.start()
    }

    Process {
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=input"]
        running: root.enabled
        stdout: SplitParser {
            onRead: checkSoon.restart()
        }
    }

    LatestProcess {
        id: check
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let mice = [];
                try {
                    mice = JSON.parse(text).mice.map(m => m.name);
                } catch (e) {
                    console.warn("Touchpad: unexpected hyprctl devices output: " + e.message);
                    return;
                }
                const found = TouchpadDevices.classify(mice);
                root.apply(found.touchpads, !(root.enabled && found.mouse));
            }
        }
    }
}
