// Snapping windows into halves, quarters and thirds of their monitor, Windows 11 style:
// Super+Left/Right (`qs ipc call snap active left`, handled in snap/SnapPicker.qml) and the
// snap menu (Super+Z). The window floats and gets the exact rectangle from SnapLayout.js, with
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

    // Where each snapped window was before it was snapped, by address: { at: [x, y], size: [w, h] }.
    // Super+Down puts it back there. Snapping a snapped window elsewhere keeps the original; a
    // window moved by hand since gets its new spot remembered. Forgotten when the window closes.
    property var saved: ({})
    // The layout each window was last snapped to, by address, so a change of gaps can place the
    // ones still there again (see the gaps Process below).
    property var layouts: ({})
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
        geometry(window, current => {
            if (!saved[window.address] || SnapLayout.snappedLayout(current, area(window.monitor), gapsOut, gapsIn) === "")
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
        delete layouts[window.address];
        Windows.run(window, "resize", `x = ${before.size[0]}, y = ${before.size[1]}`);
        Windows.run(window, "move", `x = ${before.at[0]}, y = ${before.at[1]}`);
    }

    function place(window: HyprlandToplevel, layout: string): void {
        layouts[window.address] = layout;
        const r = rect(window.monitor, layout);
        Windows.run(window, "float", `action = "enable"`);
        Windows.run(window, "resize", `x = ${r.width}, y = ${r.height}`);
        Windows.run(window, "move", `x = ${r.x}, y = ${r.y}`);
        // An app with a minimum size (Discord) may stay bigger than asked: then keep it against
        // the layout's outer side instead of sticking out past the screen (SnapLayout.fit).
        geometry(window, current => {
            if (current.size[0] <= r.width && current.size[1] <= r.height)
                return;
            const spot = SnapLayout.fit(layout, r, current.size[0], current.size[1]);
            Windows.run(window, "move", `x = ${spot.x}, y = ${spot.y}`);
        });
    }

    // The gaps changed (settings window): windows still exactly where they were snapped with the
    // old gaps move to the same layout with the new ones. Ones moved by hand since stay put.
    function replaceSnapped(oldOut: var, oldIn: int): void {
        for (const window of Windows.recent) {
            const layout = layouts[window.address];
            const info = window.lastIpcObject;
            if (!layout || !info?.at || !window.monitor)
                continue;
            const geometry = { at: info.at, size: info.size };
            if (SnapLayout.snappedLayout(geometry, area(window.monitor), oldOut, oldIn) === layout)
                place(window, layout);
        }
    }

    // Where `layout` is on `monitor`, in global logical pixels.
    function rect(monitor: HyprlandMonitor, layout: string): var {
        return SnapLayout.rect(layout, area(monitor), gapsOut, gapsIn);
    }

    // The part of `monitor` windows snap into: all of it but what bars reserve (the island), as
    // [left, top, right, bottom]; Hyprland sends that with the monitor's details, which
    // refreshMonitors() keeps current.
    function area(monitor: HyprlandMonitor): var {
        const reserved = monitor.lastIpcObject?.reserved ?? [0, 0, 0, 0];
        return {
            x: monitor.x + reserved[0],
            y: monitor.y + reserved[1],
            width: monitor.width / monitor.scale - reserved[0] - reserved[2],
            height: monitor.height / monitor.scale - reserved[1] - reserved[3]
        };
    }

    // A closed window's spot is forgotten (Hyprland can reuse its address).
    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "closewindow") {
                delete root.saved[event.data];
                delete root.layouts[event.data];
            }
        }
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

    // Gaps changed in the settings window: read them again once Hyprland has reloaded.
    Connections {
        target: Settings.values

        function onGapsInChanged(): void {
            rereadGaps.restart();
        }

        function onGapsOutChanged(): void {
            rereadGaps.restart();
        }
    }

    Timer {
        id: rereadGaps
        interval: 1500 // after HyprlandSettings' write (400 ms) and the reload
        onTriggered: gaps.running = true
    }

    Process {
        id: gaps
        command: ["sh", "-c", "hyprctl getoption general:gaps_out -j; hyprctl getoption general:gaps_in -j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // Two JSON objects, one per line: { "option": ..., "css": "20 20 20 20" }.
                try {
                    const [out, inner] = text.trim().split("\n").map(line => JSON.parse(line));
                    const oldOut = root.gapsOut;
                    const oldIn = root.gapsIn;
                    root.gapsOut = SnapLayout.parseGaps(out.css);
                    root.gapsIn = SnapLayout.parseGaps(inner.css).top;
                    root.replaceSnapped(oldOut, oldIn);
                } catch (e) {
                    console.warn("Snap: couldn't read Hyprland's gaps, using defaults: " + e.message);
                }
            }
        }
    }
}
