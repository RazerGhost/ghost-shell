// Snapping, on top of the tiling layout in Hyprland's config (hypr/layout.lua): picking a spot for a
// window (Super+Left/Right, `qs ipc call snap active left`, or the window menu) sends it to the
// layout, which arranges the whole workspace around it. A spot left empty is offered to Snap
// Assist (snap/SnapAssist.qml).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    // Hyprland's gaps_in, read at startup and when the settings change: the layout's empty cells
    // come without gaps, Snap Assist keeps them.
    property int gapsIn: 5

    // A spot was picked and the workspace has empty cells ({ x, y, width, height }, global logical
    // pixels, gaps included); Snap Assist offers windows for the first.
    signal emptyCells(HyprlandToplevel window, var cells)

    // Puts `window` in `spot` (left, right, top-left, left-third, ... see hypr/tiling.lua). A
    // floating window starts tiling. The layout message acts on the focused workspace, so the
    // window is focused first.
    function snap(window: HyprlandToplevel, spot: string): void {
        if (!window) {
            console.warn("Snap: no window to snap");
            return;
        }
        Windows.run(window, "fullscreen", `mode = "maximized", action = "unset"`);
        Windows.run(window, "fullscreen", `mode = "fullscreen", action = "unset"`);
        Windows.run(window, "float", `action = "disable"`);
        Windows.focus(window);
        Hyprland.dispatch(`hl.dsp.layout("snap ${spot} 0x${window.address}")`);
        askEmpty(window);
    }

    // Back to arranging the window's workspace by the number of windows.
    function arrangeAutomatically(window: HyprlandToplevel): void {
        Windows.focus(window);
        Hyprland.dispatch(`hl.dsp.layout("auto")`);
    }

    function toggleFloating(window: HyprlandToplevel): void {
        Windows.run(window, "float", `action = "toggle"`);
    }

    // Asks the layout for the workspace's empty cells; Snap Assist shows over the first.
    function askEmpty(window: HyprlandToplevel): void {
        if (!window?.workspace)
            return;
        empty.window = window;
        empty.command = ["hyprctl", "repl", `return ShellLayout.empty(${window.workspace.id})`];
        empty.running = true;
    }

    Process {
        id: empty

        property HyprlandToplevel window

        stdout: StdioCollector {
            onStreamFinished: {
                let cells;
                try {
                    cells = JSON.parse(text);
                } catch (e) {
                    console.warn("Snap: unexpected answer from the layout: " + text.trim());
                    return;
                }
                if (cells.length > 0)
                    root.emptyCells(empty.window, cells.map(c => ({
                        x: c.x + root.gapsIn, y: c.y + root.gapsIn,
                        width: c.width - root.gapsIn * 2, height: c.height - root.gapsIn * 2
                    })));
            }
        }
    }

    // Gaps changed in the settings window: read them again once Hyprland has reloaded.
    Connections {
        target: Settings.values

        function onGapsInChanged(): void {
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
        command: ["hyprctl", "getoption", "general:gaps_in", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // { "option": ..., "css": "5 5 5 5" }: the same on every side here.
                try {
                    root.gapsIn = parseInt(JSON.parse(text).css);
                } catch (e) {
                    console.warn("Snap: couldn't read Hyprland's gaps, using 5: " + e.message);
                }
            }
        }
    }
}
