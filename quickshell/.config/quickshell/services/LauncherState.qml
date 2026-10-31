// The launcher's state (launcher/Launcher.qml), here so the rest of the shell can open it on one
// of its pages: Settings and Wallpapers grow out of the search bar (user's choice, 2026-10-31,
// instead of windows of their own), and Super+U opens it on the customize tiles.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property alias open: persist.open
    // "" (the search), "settings" or "wallpapers".
    property alias page: persist.page
    // Settings' page (SettingsPages.js ids).
    property alias settingsPage: persist.settingsPage
    // Super+U: the customize tiles take the keyboard when it opens.
    property bool customize: false

    // Stays open on the same page when the shell reloads (after editing its files).
    PersistentProperties {
        id: persist
        reloadableId: "launcherState"

        property bool open: false
        property string page: ""
        property string settingsPage: "appearance"
    }

    // A page's size: compact (the search bar's width, one column), large, or full (the screen).
    // The last one picked is kept (Settings' launcherPanelSize).
    readonly property var sizes: ["compact", "large", "full"]
    readonly property string size: sizes.includes(Settings.values.launcherPanelSize) ? Settings.values.launcherPanelSize : "large"

    // One step larger (by 1) or smaller (by -1).
    function resize(by: int): void {
        const next = sizes[Math.max(0, Math.min(sizes.length - 1, sizes.indexOf(size) + by))];
        if (next !== size)
            Settings.values.launcherPanelSize = next;
    }

    function toggle(): void {
        if (open) {
            open = false;
        } else {
            page = "";
            customize = false;
            open = true;
        }
    }

    function show(name: string): void {
        page = name;
        customize = false;
        open = true;
    }

    function showSettings(id: string): void {
        if (id !== "")
            settingsPage = id;
        show("settings");
    }

    function showCustomize(): void {
        // Again while it's showing them: closes, like the menu it replaced.
        if (open && page === "" && customize) {
            open = false;
            return;
        }
        page = "";
        customize = true;
        open = true;
    }
}
