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

    // Where each snapped window was before its first snap, by address: { at: [x, y], size: [w, h] }.
    // Super+Down puts it back there (snapping again elsewhere keeps the original).
    property var saved: ({})
    // Callbacks waiting for `hyprctl clients -j` (see geometry()).
    property var pending: []

    // A window was snapped by the user (not by Snap Assist); snap/SnapAssist.qml offers the
    // other windows for the rest of the screen.
    signal snapped(HyprlandToplevel window, string layout)

    // assisted: Snap Assist placing the second window, which shouldn't start another round.
    function snap(window: HyprlandToplevel, layout: string, assisted: bool): void {
        if (!window?.monitor) {
            console.warn("Snap: no window or monitor to snap");
            return;
        }
        Hyprland.refreshMonitors(); // keeps `reserved` below current for the next snap
        // A maximized or fullscreen window has to leave that state first.
        Windows.run(window, "fullscreen", `mode = "maximized", action = "unset"`);
        Windows.run(window, "fullscreen", `mode = "fullscreen", action = "unset"`);
        const done = () => {
            place(window, layout);
            if (!assisted)
                snapped(window, layout);
        };
        if (saved[window.address]) {
            done();
            return;
        }
        geometry(window, current => {
            saved[window.address] = current;
            done();
        });
    }

    // Super+Down: a snapped window goes back to where it was before snapping; any other window
    // is minimized (like Windows).
    function restoreOrMinimize(window: HyprlandToplevel): void {
        if (!window)
            return;
        const before = saved[window.address];
        if (!before) {
            Windows.minimize(window);
            return;
        }
        delete saved[window.address];
        Windows.run(window, "resize", `x = ${before.size[0]}, y = ${before.size[1]}`);
        Windows.run(window, "move", `x = ${before.at[0]}, y = ${before.at[1]}`);
    }

    function place(window: HyprlandToplevel, layout: string): void {
        const r = rect(window.monitor, layout);
        Windows.run(window, "float", `action = "enable"`);
        Windows.run(window, "resize", `x = ${r.width}, y = ${r.height}`);
        Windows.run(window, "move", `x = ${r.x}, y = ${r.y}`);
    }

    // Where `layout` is on `monitor`, in global logical pixels.
    function rect(monitor: HyprlandMonitor, layout: string): var {
        // Space bars reserve (the island), as [left, top, right, bottom]; Hyprland sends it with
        // the monitor's details, which refreshMonitors() keeps current.
        const reserved = monitor.lastIpcObject?.reserved ?? [0, 0, 0, 0];
        const area = {
            x: monitor.x + reserved[0],
            y: monitor.y + reserved[1],
            width: monitor.width / monitor.scale - reserved[0] - reserved[2],
            height: monitor.height / monitor.scale - reserved[1] - reserved[3]
        };
        return SnapLayout.rect(layout, area, gapsOut, gapsIn);
    }

    // The window's current position and size, straight from Hyprland: Quickshell's copy
    // (lastIpcObject) is only as fresh as its last refresh.
    function geometry(window: HyprlandToplevel, callback: var): void {
        pending.push({ address: "0x" + window.address, callback: callback });
        clients.running = true;
    }

    Process {
        id: clients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const waiting = root.pending;
                root.pending = [];
                let list = [];
                try {
                    list = JSON.parse(text);
                } catch (e) {
                    console.warn("Snap: unexpected hyprctl clients output: " + e.message);
                    return;
                }
                for (const request of waiting) {
                    const client = list.find(c => c.address === request.address);
                    if (client)
                        request.callback({ at: client.at, size: client.size });
                }
            }
        }
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
