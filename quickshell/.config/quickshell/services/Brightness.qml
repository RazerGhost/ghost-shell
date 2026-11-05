// Screen brightness, read with brightnessctl.
//
// The kernel doesn't send file-change events for /sys/class/backlight, so this can't watch
// for changes. The brightness keybinds call `qs ipc call brightness refresh` after
// brightnessctl instead (see hypr/binds.lua), which re-reads the value and shows the OSD.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0-1; -1 until the first read finishes.
    property real level: -1

    // Emitted when a refresh from IPC has read the new value, or change() set one (the OSD shows
    // it); not for the read at startup.
    signal changed()

    property bool emitOnRead: false

    // Set from the quick settings slider; level is 0-1. Doesn't show the OSD.
    // A drag sends many values while brightnessctl is still running; only the latest is
    // applied once the current run exits.
    function set(level: real): void {
        // Kept within what brightnessctl is given: the island's wheel would otherwise take it
        // past 100 % or below 0 (where change() stops).
        root.level = Math.max(0.01, Math.min(1, level)); // the slider moves now, not once brightnessctl finishes
        pending = Math.round(root.level * 100);
        if (!write.running)
            apply();
    }

    // Up or down by `by` (the island's wheel), with the pop-up like the keys.
    function change(by: real): void {
        if (level < 0)
            return;
        set(level + by);
        changed();
    }

    property int pending: -1
    property int applied: -1

    function apply(): void {
        applied = pending;
        write.command = ["brightnessctl", "-c", "backlight", "-q", "set", pending + "%"];
        write.running = true;
    }

    Process {
        id: write
        onExited: {
            if (root.pending !== root.applied)
                root.apply();
        }
    }

    Process {
        id: read
        // -m prints machine-readable output: "amdgpu_bl1,backlight,128,50%,255"
        // (device, class, current, percent, max). Always the backlight class: without it
        // brightnessctl takes the first device it finds, which on the desktop (no backlight) was a
        // keyboard LED, so the slider, wheel and keys dimmed that (2026-11-05).
        command: ["brightnessctl", "-c", "backlight", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // Nothing: no backlight (a desktop's monitors); `level` stays -1 and brightness hides.
                if (text.trim() === "")
                    return;
                const fields = text.trim().split(",");
                const current = Number(fields[2]);
                const max = Number(fields[4]);
                if (fields.length < 5 || !(max > 0)) {
                    console.warn("Brightness: unexpected brightnessctl output: " + text);
                    return;
                }
                root.level = current / max;
                if (root.emitOnRead)
                    root.changed();
                root.emitOnRead = false;
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function refresh(): void {
            root.emitOnRead = true;
            read.running = true;
        }
    }
}
