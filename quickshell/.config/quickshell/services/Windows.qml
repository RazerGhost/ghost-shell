// Window actions for the island's window menu, and "minimizing". Hyprland has no minimize, so a
// minimized window is moved to a hidden special workspace; restoring moves it back to the
// workspace you're on.
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

    // Every window, most recently used first, by Hyprland's focus history (0 = the focused
    // window). The history is part of each window's details: call Hyprland.refreshToplevels()
    // first when the order has to be fresh.
    readonly property list<HyprlandToplevel> recent: (Hyprland.toplevels?.values ?? [])
        .filter(t => t.wayland !== null)
        .sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 999) - (b.lastIpcObject?.focusHistoryID ?? 999))

    // The focused window. Hyprland.activeToplevel only updates on focus changes, so it's null
    // until the first one after the shell starts; Wayland's window list knows it from the start.
    // A minimized window doesn't count: Hyprland can still call it active after moving it away.
    readonly property HyprlandToplevel active: {
        const window = Hyprland.activeToplevel
            ?? (Hyprland.toplevels?.values ?? []).find(t => t.wayland !== null && t.wayland === ToplevelManager.activeToplevel)
            ?? null;
        return window?.workspace?.name === minimizedWorkspace ? null : window;
    }

    // Windows that asked for attention (an app can't take the focus by itself, like on Windows,
    // so Hyprland marks it urgent instead), oldest first. The island shows the first one. A window
    // leaves the list once it's focused or closed (closed ones turn into null).
    // Kept here rather than read from HyprlandToplevel.urgent, which didn't follow these events
    // (it stayed false for a terminal bell).
    property list<HyprlandToplevel> attention: []
    readonly property HyprlandToplevel needsAttention: attention.find(t => t !== null) ?? null

    // The island has shown the current one long enough.
    function attentionSeen(): void {
        const seen = needsAttention;
        attention = attention.filter(t => t !== null && t !== seen);
    }

    Connections {
        target: Hyprland

        // "urgent>>55e5..." (the window's address, without 0x). No type on `event`: its C++ type
        // isn't registered under a QML name, and annotating it makes Qt complain on every event.
        function onRawEvent(event): void {
            if (event.name !== "urgent")
                return;
            const window = (Hyprland.toplevels?.values ?? []).find(t => t.address === event.data);
            if (window && window !== Hyprland.activeToplevel && !root.attention.includes(window))
                root.attention = [...root.attention.filter(t => t !== null), window];
        }

        // A window that gets focus no longer needs attention. This also drops a just-opened window:
        // opening one sends "urgent" right before focusing it.
        function onActiveToplevelChanged(): void {
            root.attention = root.attention.filter(t => t !== null && t !== Hyprland.activeToplevel);
        }
    }

    // Hyprland's window selector. Quickshell gives the address without the "0x".
    function selector(window: HyprlandToplevel): string {
        return "address:0x" + window.address;
    }

    // Runs a hl.dsp.window.* dispatcher on `window`; `args` is the rest of the Lua table.
    function run(window: HyprlandToplevel, dispatcher: string, args: string): void {
        Hyprland.dispatch(`hl.dsp.window.${dispatcher}({ window = "${selector(window)}"${args ? ", " + args : ""} })`);
    }

    // Like on Windows, the next most recently used window on the workspace gets the focus.
    function minimize(window: HyprlandToplevel): void {
        const workspace = window.workspace;
        run(window, "move", `workspace = "${minimizedWorkspace}", follow = false`);
        const next = recent.find(t => t !== window && t.workspace === workspace);
        if (next)
            focus(next);
    }

    // The most recently used window of an app, from what notifications and media players say
    // about themselves: a .desktop name ("spotify", "vesktop") or a display name ("Vesktop").
    // Matches the window's app id, its .desktop entry's id, or that entry's name. null if none.
    function forApp(name: string): HyprlandToplevel {
        const n = name.toLowerCase();
        if (n === "")
            return null;
        return recent.find(t => {
            const appId = t.wayland.appId.toLowerCase();
            const entry = DesktopEntries.heuristicLookup(t.wayland.appId);
            return appId === n || entry?.id.toLowerCase() === n || entry?.name.toLowerCase() === n;
        }) ?? null;
    }

    // Switch to a window: brought back first if it's minimized. What clicking a window anywhere
    // does (Alt+Tab, the dock, the overview, the attention card, the media cover).
    function show(window: HyprlandToplevel): void {
        if (window.workspace?.name === minimizedWorkspace)
            restore(window);
        else
            focus(window);
    }

    function restore(window: HyprlandToplevel): void {
        run(window, "move", `workspace = ${Hyprland.focusedWorkspace?.id ?? 1}, follow = false`);
        focus(window);
    }

    // Focus a window and bring it to the front. Focus alone doesn't raise a floating window
    // above the others.
    function focus(window: HyprlandToplevel): void {
        Hyprland.dispatch(`hl.dsp.focus({ window = "${selector(window)}" })`);
        run(window, "alter_zorder", `mode = "top"`);
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

    function moveToWorkspace(window: HyprlandToplevel, id: int): void {
        run(window, "move", `workspace = ${id}, follow = false`);
    }

    // Icon theme name for the window's app, from its .desktop file when one matches.
    function iconFor(window: HyprlandToplevel): string {
        const appId = window?.wayland?.appId ?? "";
        return DesktopEntries.heuristicLookup(appId)?.icon || appId;
    }
}
