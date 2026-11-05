// The main keyboard's layout and caps lock, for the OSD's pop-ups and the lock screen's hints.
// Each signal fires only on a real change after start-up, never for the state found at start.
// - Layout: Hyprland's activelayout event comes for every keyboard (virtual ones too, like
//   wtype's for the emoji picker) and again for the same layout, so only a new name on the main
//   keyboard counts. Its name and layout are read from `hyprctl devices -j` at start (Hyprland
//   sends no event then). Parsing in KeyboardDevices.js (tested).
// - Caps lock: no event at all, and Hyprland doesn't run a bind on the key (tried: a release
//   bind that leaves the key alone never fired). Its light follows it: the keyboard's
//   `::capslock` LED in sysfs, read in-process 4 times a second (sysfs files send no change
//   events, like the backlight's). Every keyboard's: with two (the desktop's wired and wireless
//   ones) only the first was read, so caps lock typed on the other never showed (2026-11-05). On
//   while any is on; the list is read again when udev adds or removes an LED (a keyboard
//   plugged in later).
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
    property int layoutCount: 1 // more than one: the lock screen names the active one
    property list<string> capsLeds: [] // every keyboard's caps lock LED folder
    property string capsState: "" // "1" or "0" once read; "" until then
    readonly property bool capsLock: capsState !== "" && capsState !== "0"

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
                    root.layoutCount = main.layouts;
                }
            }
        }
    }

    Process {
        id: listLeds
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.capsLeds = text.split("\n").filter(line => line !== "")
        }
    }

    // A keyboard plugged in or out adds or removes its LEDs: list them again a moment after.
    Process {
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=leds"]
        running: true
        stdout: SplitParser {
            onRead: relist.restart()
        }
    }

    Timer {
        id: relist
        interval: 1000
        onTriggered: listLeds.running = true
    }

    Instantiator {
        id: capsFiles
        model: root.capsLeds

        FileView {
            required property string modelData
            path: modelData + "/brightness"
            blockLoading: true // read right away in the timer
        }
    }

    Timer {
        interval: 250
        running: root.capsLeds.length > 0
        repeat: true
        onTriggered: {
            let read = false, on = false;
            for (let i = 0; i < capsFiles.count; i++) {
                const file = capsFiles.objectAt(i);
                file.reload();
                const value = file.text().trim();
                if (value === "")
                    continue;
                read = true;
                on = on || value !== "0";
            }
            const state = on ? "1" : "0";
            if (!read || state === root.capsState)
                return;
            const first = root.capsState === "";
            root.capsState = state;
            if (!first)
                root.capsLockSwitched(on);
        }
    }
}
