// Window actions for the island's window menu, and "minimizing". Hyprland has no minimize, so a
// minimized window is moved to a hidden special workspace; restoring moves it back to the
// workspace you're on. The Super+Down bind in hypr/binds.lua uses the same workspace name.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    readonly property string minimizedWorkspace: "special:minimized"
    readonly property list<HyprlandToplevel> minimized: (Hyprland.toplevels?.values ?? [])
        .filter(t => t.workspace?.name === minimizedWorkspace)

    // The focused window. Hyprland.activeToplevel only updates on focus changes, so it's null
    // until the first one after the shell starts; Wayland's window list knows it from the start.
    readonly property HyprlandToplevel active: Hyprland.activeToplevel
        ?? Hyprland.toplevels.values.find(t => t.wayland !== null && t.wayland === ToplevelManager.activeToplevel)
        ?? null

    // Hyprland's window selector. Quickshell gives the address without the "0x".
    function selector(window: HyprlandToplevel): string {
        return "address:0x" + window.address;
    }

    // Runs a hl.dsp.window.* dispatcher on `window`; `args` is the rest of the Lua table.
    function run(window: HyprlandToplevel, dispatcher: string, args: string): void {
        Hyprland.dispatch(`hl.dsp.window.${dispatcher}({ window = "${selector(window)}"${args ? ", " + args : ""} })`);
    }

    function minimize(window: HyprlandToplevel): void {
        run(window, "move", `workspace = "${minimizedWorkspace}", follow = false`);
    }

    function restore(window: HyprlandToplevel): void {
        run(window, "move", `workspace = ${Hyprland.focusedWorkspace?.id ?? 1}, follow = false`);
        Hyprland.dispatch(`hl.dsp.focus({ window = "${selector(window)}" })`);
    }

    function close(window: HyprlandToplevel): void {
        run(window, "close", "");
    }

    function toggleMaximized(window: HyprlandToplevel): void {
        run(window, "fullscreen", `mode = "maximized", action = "toggle"`);
    }

    function toggleFullscreen(window: HyprlandToplevel): void {
        run(window, "fullscreen", `mode = "fullscreen", action = "toggle"`);
    }

    function toggleFloating(window: HyprlandToplevel): void {
        run(window, "float", `action = "toggle"`);
    }

    function moveToWorkspace(window: HyprlandToplevel, id: int): void {
        run(window, "move", `workspace = ${id}, follow = false`);
    }

    // Icon theme name for the window's app, from its .desktop file when one matches.
    function iconFor(window: HyprlandToplevel): string {
        const appId = window?.wayland?.appId ?? "";
        return DesktopEntries.heuristicLookup(appId)?.icon || appId;
    }
}
