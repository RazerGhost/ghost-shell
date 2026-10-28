import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "DockApps.js" as DockApps

// The dock: an island along the bottom edge with your pinned apps and the other running ones
// (dock/DockBar.qml draws it on each monitor). It slides away when a window covers it and
// comes back when the pointer touches the bottom edge.
Scope {
    id: root

    // Pinned apps as desktop entry ids, in order. Saved next to the other shell state, outside
    // the shell directory (a change there would reload the shell).
    readonly property list<string> pinned: state.pinned

    // Every window with a Wayland handle, most recently used first.
    readonly property list<HyprlandToplevel> windows: (Hyprland.toplevels?.values ?? [])
        .filter(t => t.wayland !== null)
        .sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 999) - (b.lastIpcObject?.focusHistoryID ?? 999))

    // { id, pinned, windows } per app; see DockApps.items.
    readonly property var items: DockApps.items(
        windows.map(t => ({ appId: t.wayland.appId, window: t })),
        pinned,
        appId => DesktopEntries.heuristicLookup(appId)?.id ?? "")

    function togglePin(id: string): void {
        state.pinned = pinned.includes(id) ? pinned.filter(p => p !== id) : [...pinned, id];
        file.writeAdapter();
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/dock.json"
        printErrors: false // missing until something is pinned or unpinned

        adapter: JsonAdapter {
            id: state
            property list<string> pinned: ["zen", "com.mitchellh.ghostty", "org.gnome.Nautilus", "dev.zed.Zed",
                                           "spotify", "vesktop", "steam"]
        }
    }

    // Window positions for hiding the dock. Hyprland sends no event when a window is moved or
    // resized, so re-read them once a second, and right away when windows open, close or change.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2"]
                    .includes(event.name))
                Hyprland.refreshToplevels();
        }
    }

    Variants {
        model: Quickshell.screens

        DockBar {
            required property ShellScreen modelData
            screen: modelData
            dock: root
        }
    }
}
