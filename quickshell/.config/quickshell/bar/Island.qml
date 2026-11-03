import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services

// The bar: an "island" at the top of each monitor (floating, or attached to the edge) showing the
// time and what needs attention. A click morphs it into the "today" menu (calendar), a
// right-click into "settings" (quick settings). While music plays, a "live activity" (the cover)
// takes the time's place: hovering it shows a small player (and the time again), clicking it or
// the player opens the "media" menu. Switching workspaces shows the dots for a moment. New
// notifications pop up in the top-right corner of the
// focused monitor (PopupStack.qml). One menu is open at a time, on one monitor; click outside it
// or press Escape to close it. This file holds that shared state; IslandWindow.qml draws the
// island on each monitor.
Scope {
    id: root

    // "", "today", "settings", "media", "power", "tray", "clipboard" or "emoji"
    property alias panel: persist.panel
    property alias screenName: persist.screenName // the monitor the menu is open on

    // The open menu stays open when the shell reloads (after editing its files).
    PersistentProperties {
        id: persist
        reloadableId: "island"

        property string panel: ""
        property string screenName: ""
    }

    // Quick settings opens in its edit mode when it's next shown, or at once if it's open
    // (editQuickSettings below, for the customize menu).
    property bool quickEdit: false

    // After the shell reloads (a file in its folder changed), the island says so instead of
    // Quickshell's own pop-up: briefly when it worked, longer with the error when it didn't (the
    // old shell keeps running then).
    property bool reloadShown: false
    property string reloadError: ""

    Connections {
        target: Quickshell

        function onReloadCompleted(): void {
            Quickshell.inhibitReloadPopup();
            root.reloadError = "";
            root.reloadShown = true;
            reloadTimer.restart();
        }

        function onReloadFailed(error: string): void {
            Quickshell.inhibitReloadPopup();
            root.reloadError = error;
            root.reloadShown = true;
            reloadTimer.restart();
        }
    }

    Timer {
        id: reloadTimer
        interval: root.reloadError ? 10000 : 2000
        onTriggered: root.reloadShown = false
    }

    function toggle(name: string, screen: string): void {
        if (panel === name && screenName === screen) {
            panel = "";
        } else {
            panel = name;
            screenName = screen;
        }
    }

    // From Hyprland binds: qs ipc call island toggle settings (or: today, media, power, tray,
    // clipboard, emoji)
    IpcHandler {
        target: "island"

        function toggle(panel: string): void {
            root.toggle(panel, Hyprland.focusedMonitor?.name ?? "");
        }

        function close(): void {
            root.panel = "";
        }

        // Quick settings in its edit mode (the customize menu's Quick settings).
        function editQuickSettings(): void {
            // The screen first: setting the panel first opened it on the last screen for a moment,
            // whose quick settings took the flag.
            root.screenName = Hyprland.focusedMonitor?.name ?? "";
            root.panel = "settings";
            root.quickEdit = true;
        }
    }

    // Notifications, a window asking for attention and the reload notice, in the corner.
    PopupStack {
        island: root
    }

    // One island per monitor: Variants creates a delegate for each entry in the model
    // and destroys it when the monitor goes away.
    Variants {
        model: Quickshell.screens

        IslandWindow {
            island: root
        }
    }
}
