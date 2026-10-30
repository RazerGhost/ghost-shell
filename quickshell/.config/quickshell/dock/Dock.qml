import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "DockApps.js" as DockApps

// The dock: an island along the bottom edge with your pinned apps and the other running ones
// (dock/DockBar.qml draws it on each monitor). Hidden until the pointer touches the bottom edge
// (user's choice, since windows tile); Settings -> Windows -> Dock can keep it shown (then it
// reserves its space, like a taskbar) or turn it off.
Scope {
    id: root

    // Pinned apps as desktop entry ids, in order. Saved next to the other shell state, outside
    // the shell directory (a change there would reload the shell).
    readonly property list<string> pinned: state.pinned

    // { id, pinned, windows } per app, windows most recently used first; see DockApps.items.
    readonly property var items: DockApps.items(
        Windows.recent.map(t => ({ appId: t.wayland.appId, window: t })),
        pinned,
        appId => DesktopEntries.heuristicLookup(appId)?.id ?? "")

    function movePin(id: string, by: int): void {
        state.pinned = DockApps.movePin(pinned, id, by);
        file.writeAdapter();
    }

    function placePin(id: string, index: int): void {
        state.pinned = DockApps.placePin(pinned, id, index);
        file.writeAdapter();
    }

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

    // Settings -> Windows -> Dock: "off" shows none.
    Variants {
        model: Settings.values.dockMode === "off" ? [] : Quickshell.screens

        DockBar {
            required property ShellScreen modelData
            screen: modelData
            dock: root
        }
    }
}
