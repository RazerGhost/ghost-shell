// Turns the touchpad off while a mouse is connected (Settings -> Keyboard and mouse; off by
// default), and on again when it's gone. Hyprland sends no event when a mouse is plugged in, so
// its devices are read every 3 seconds while the setting is on (TouchpadDevices.js, tested);
// the touchpads are switched with `hl.device` through `hyprctl eval`, only when that changes.
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

    // The setting switched off: the touchpad back on.
    onEnabledChanged: {
        if (!enabled)
            check.running = true;
    }

    Timer {
        interval: 3000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    Process {
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
