// Snapping windows into halves, quarters and thirds of their monitor, Windows 11 style:
// Super+Left/Right (`qs ipc call snap active left`, handled in snap/WindowMenu.qml) and the
// window menu (Alt+Space or Super+Z). The window floats and gets the exact rectangle from SnapLayout.js, with
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
    // Where each window was last snapped, by address: { layout, x, y, width, height }, the size it
    // really took (an app may refuse to shrink). A window still exactly there counts as snapped:
    // a change of gaps places it again, and the windows next to it make room for it.
    property var snaps: ({})
    // Callbacks waiting for `hyprctl clients -j` (see geometry()).
    property var pending: []
    // Callbacks waiting for windows to take their new size (see afterResize()).
    property var settling: []

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
            place(window, layout, null);
            if (!assisted)
                snapped(window, layout);
        };
        geometry(window, current => {
            if (!saved[window.address] || !stillSnapped(current))
                saved[window.address] = { at: current.at, size: current.size };
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
        delete snaps[window.address];
        Windows.run(window, "resize", `x = ${before.size[0]}, y = ${before.size[1]}`);
        Windows.run(window, "move", `x = ${before.at[0]}, y = ${before.at[1]}`);
    }

    // done: called once the window is in its spot (replaceSnapped places windows one by one).
    function place(window: HyprlandToplevel, layout: string, done: var): void {
        Windows.run(window, "float", `action = "enable"`);
        geometry(window, (current, clients) => {
            // Next to a snapped window that won't shrink, take the space it leaves.
            const others = neighbours(current, clients);
            const r = others.reduce((t, n) => SnapLayout.trim(t, n.rect, gapsIn * 2), rect(window.monitor, layout));
            Windows.run(window, "resize", `x = ${r.width}, y = ${r.height}`);
            Windows.run(window, "move", `x = ${r.x}, y = ${r.y}`);
            afterResize(() => geometry(window, placed => {
                // An app with a minimum size (Discord) may stay bigger than asked: then it stays
                // against the layout's outer side (SnapLayout.fit) and its neighbours make room.
                const spot = SnapLayout.fit(layout, r, placed.size[0], placed.size[1]);
                if (spot.x !== r.x || spot.y !== r.y)
                    Windows.run(window, "move", `x = ${spot.x}, y = ${spot.y}`);
                const final = { x: spot.x, y: spot.y, width: placed.size[0], height: placed.size[1] };
                snaps[window.address] = Object.assign({ layout: layout }, final);
                if (final.width > r.width || final.height > r.height)
                    for (const n of others)
                        makeRoom(n.window, n.layout, final);
                done?.();
            }));
        });
    }

    // `window` (snapped to `layout`) shrinks to end a gap short of `other`, a window that won't.
    function makeRoom(window: HyprlandToplevel, layout: string, other: var): void {
        const r = SnapLayout.trim(rect(window.monitor, layout), other, gapsIn * 2);
        Windows.run(window, "resize", `x = ${r.width}, y = ${r.height}`);
        Windows.run(window, "move", `x = ${r.x}, y = ${r.y}`);
        afterResize(() => geometry(window, placed => snaps[window.address] = {
            layout: layout, x: placed.at[0], y: placed.at[1], width: placed.size[0], height: placed.size[1]
        }));
    }

    // Whether a window (a `hyprctl clients` entry) is still exactly where it was snapped.
    function stillSnapped(client: var): bool {
        const s = snaps[client.address.slice(2)];
        return !!s && s.x === client.at[0] && s.y === client.at[1]
            && s.width === client.size[0] && s.height === client.size[1];
    }

    // The other snapped windows on `client`'s workspace, as { window, layout, rect }.
    function neighbours(client: var, clients: var): var {
        const result = [];
        for (const c of clients) {
            if (c.address === client.address || c.workspace.id !== client.workspace.id || !stillSnapped(c))
                continue;
            const window = Windows.recent.find(t => "0x" + t.address === c.address);
            if (window)
                result.push({
                    window: window,
                    layout: snaps[window.address].layout,
                    rect: { x: c.at[0], y: c.at[1], width: c.size[0], height: c.size[1] }
                });
        }
        return result;
    }

    // The gaps changed (settings window): windows still exactly where they were snapped move to
    // the same layout with the new gaps, one after another so each sees its neighbours' new
    // spots. Ones moved by hand since stay put.
    function replaceSnapped(): void {
        const queue = Windows.recent.filter(t => snaps[t.address] && t.monitor);
        const next = () => {
            const window = queue.shift();
            if (window)
                geometry(window, current => {
                    if (stillSnapped(current))
                        place(window, snaps[window.address].layout, next);
                    else
                        next();
                });
        };
        next();
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
                delete root.snaps[event.data];
            }
        }
    }

    // The window's current details (at, size, workspace, address), straight from Hyprland:
    // Quickshell's copy (lastIpcObject) is only as fresh as its last refresh. The callback also
    // gets every window's, for neighbours().
    function geometry(window: HyprlandToplevel, callback: var): void {
        pending.push({ address: "0x" + window.address, callback: callback });
        clients.running = true;
    }

    // Runs `callback` once the app has had time to take its new size: right after a resize,
    // Hyprland still reports the size it asked for, not the one an app with a minimum size keeps.
    function afterResize(callback: var): void {
        settling.push(callback);
        settle.restart();
    }

    Timer {
        id: settle
        interval: 300
        onTriggered: {
            const waiting = root.settling;
            root.settling = [];
            for (const callback of waiting)
                callback();
        }
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
                        request.callback(client, list);
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
                    root.gapsOut = SnapLayout.parseGaps(out.css);
                    root.gapsIn = SnapLayout.parseGaps(inner.css).top;
                    root.replaceSnapped();
                } catch (e) {
                    console.warn("Snap: couldn't read Hyprland's gaps, using defaults: " + e.message);
                }
            }
        }
    }
}
