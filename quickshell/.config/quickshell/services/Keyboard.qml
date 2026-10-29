// The main keyboard's layout and caps lock, for the OSD's pop-ups. Each signal fires only on a
// real change after start-up, never for the state found at start.
// - Layout: Hyprland's activelayout event comes for every keyboard (virtual ones too, like
//   wtype's for the emoji picker) and again for the same layout, so only a new name on the main
//   keyboard counts. Its name and layout are read from `hyprctl devices -j` at start (Hyprland
//   sends no event then). Parsing in KeyboardDevices.js (tested).
// - Caps lock: no event at all, and Hyprland doesn't run a bind on the key (tried: a release
//   bind that leaves the key alone never fired). Its light follows it: the keyboard's
//   `::capslock` LED in sysfs, read in-process 4 times a second (sysfs files send no change
//   events, like the backlight's).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "KeyboardDevices.js" as KeyboardDevices

Singleton {
    id: root

    property string layout: ""
    property string mainKeyboard: ""
    property string capsLed: ""
    property string capsState: "" // the LED's brightness; "" until first read

    signal layoutSwitched(string name)
    signal capsLockSwitched(bool on)

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "activelayout")
                return;
            const active = KeyboardDevices.activeLayout(event.data);
            if (!active || active.keyboard !== root.mainKeyboard || active.layout === root.layout)
                return;
            root.layout = active.layout;
            root.layoutSwitched(active.layout);
        }
    }

    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const main = KeyboardDevices.mainKeyboard(text);
                if (main) {
                    root.mainKeyboard = main.name;
                    root.layout = main.layout;
                }
            }
        }
    }

    Process {
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.capsLed = text.trim()
        }
    }

    FileView {
        id: capsFile
        path: root.capsLed !== "" ? root.capsLed + "/brightness" : ""
        blockLoading: true // read right away in the timer
    }

    Timer {
        interval: 250
        running: root.capsLed !== ""
        repeat: true
        onTriggered: {
            capsFile.reload();
            const state = capsFile.text().trim();
            if (state === "" || state === root.capsState)
                return;
            const first = root.capsState === "";
            root.capsState = state;
            if (!first)
                root.capsLockSwitched(state !== "0");
        }
    }
}
