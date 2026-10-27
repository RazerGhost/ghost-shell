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

    // Emitted when a refresh from IPC has read the new value; not for the read at startup.
    signal changed()

    property bool emitOnRead: false

    Process {
        id: read
        // -m prints machine-readable output: "amdgpu_bl1,backlight,128,50%,255"
        // (device, class, current, percent, max).
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
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
