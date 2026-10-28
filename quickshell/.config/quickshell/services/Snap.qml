// Snapping windows into halves, quarters and thirds of their monitor, Windows 11 style:
// Super+Left/Right (`qs ipc call snap active left`, handled in bar/Island.qml) and the snap
// menu (Super+Z). The window floats and gets the exact rectangle from SnapLayout.js, with
// Hyprland's own gaps.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "SnapLayout.js" as SnapLayout

Singleton {
    id: root

    // From look.lua, read from Hyprland so they stay in sync. Until then, look.lua's values.
    property var gapsOut: SnapLayout.parseGaps("20")
    property int gapsIn: 5

    function snap(window: HyprlandToplevel, layout: string): void {
        const monitor = window?.monitor;
        Hyprland.refreshMonitors(); // keeps `reserved` below current for the next snap
        if (!monitor) {
            console.warn("Snap: no window or monitor to snap");
            return;
        }
        // Space bars reserve (the island), as [left, top, right, bottom]; Hyprland sends it with
        // the monitor's details, which refreshMonitors() keeps current.
        const reserved = monitor.lastIpcObject?.reserved ?? [0, 0, 0, 0];
        const area = {
            x: monitor.x + reserved[0],
            y: monitor.y + reserved[1],
            width: monitor.width / monitor.scale - reserved[0] - reserved[2],
            height: monitor.height / monitor.scale - reserved[1] - reserved[3]
        };
        const r = SnapLayout.rect(layout, area, gapsOut, gapsIn);
        // A maximized or fullscreen window has to leave that state first.
        Windows.run(window, "fullscreen", `mode = "maximized", action = "unset"`);
        Windows.run(window, "fullscreen", `mode = "fullscreen", action = "unset"`);
        Windows.run(window, "float", `action = "enable"`);
        Windows.run(window, "resize", `x = ${r.width}, y = ${r.height}`);
        Windows.run(window, "move", `x = ${r.x}, y = ${r.y}`);
    }

    Component.onCompleted: Hyprland.refreshMonitors()

    Process {
        command: ["sh", "-c", "hyprctl getoption general:gaps_out -j; hyprctl getoption general:gaps_in -j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // Two JSON objects, one per line: { "option": ..., "css": "20 20 20 20" }.
                try {
                    const [out, inner] = text.trim().split("\n").map(line => JSON.parse(line));
                    root.gapsOut = SnapLayout.parseGaps(out.css);
                    root.gapsIn = SnapLayout.parseGaps(inner.css).top;
                } catch (e) {
                    console.warn("Snap: couldn't read Hyprland's gaps, using defaults: " + e.message);
                }
            }
        }
    }
}
