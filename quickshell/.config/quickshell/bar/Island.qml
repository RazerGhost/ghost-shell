import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.theme

// The bar: an "island" at the top of each monitor (floating, or attached to the edge) showing the
// time and what needs attention. A click morphs it into the "today" menu (calendar), a
// right-click into "settings" (quick settings). While music plays, a "live activity" (the cover)
// takes the time's place: hovering it shows a small player (and the time again), clicking it or
// the player opens the "media" menu. Switching workspaces shows the dots for a moment. New
// notifications pop out of the island on the focused monitor, one at a time, then a window
// asking for attention. One menu is open at a time, on one monitor; click outside it
// or press Escape to close it. This file holds that shared state; IslandWindow.qml draws the
// island on each monitor.
Scope {
    id: root

    // "", "today", "settings", "media", "power", "clipboard" or "wallpaper"
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
    // Quick settings is to open on one of its pages ("system", "apps", ...; `island page`).
    property string quickPage: ""
    // The today menu is to open on one of its parts ("timer": the island's timer alert).
    property string todayPart: ""

    // After the shell reloads (a file in its folder changed), the island says so instead of
    // Quickshell's own pop-up: briefly when it worked, longer with the error when it didn't (the
    // old shell keeps running then).
    property bool reloadShown: false
    property string reloadError: ""

    // After the lock screen lets you in, the island greets you for a moment with what's waiting
    // (WelcomeCard.qml); pop-ups wait for it. `welcomeFirst`: the login's unlock.
    property bool welcomeShown: false
    property bool welcomeFirst: false

    // The wallpaper picker is an island menu; Wallpaper.pickerOpen (the IPC, quick settings'
    // button, the slideshow's pause) follows it both ways.
    onPanelChanged: Wallpaper.pickerOpen = panel === "wallpaper"
    Connections {
        target: Wallpaper
        function onPickerOpenChanged(): void {
            if (Wallpaper.pickerOpen && root.panel !== "wallpaper") {
                root.screenName = Hyprland.focusedMonitor?.name ?? "";
                root.panel = "wallpaper";
            } else if (!Wallpaper.pickerOpen && root.panel === "wallpaper") {
                root.panel = "";
            }
        }
    }

    Connections {
        target: Session

        function onUnlocked(first: bool): void {
            root.welcomeFirst = first;
            root.welcomeShown = true;
            welcomeTimer.restart();
        }
    }

    // The pointer rests on the greeting: it stays until the pointer leaves, then its full time.
    function holdWelcome(held: bool): void {
        if (held)
            welcomeTimer.stop();
        else if (welcomeShown)
            welcomeTimer.restart();
    }

    Timer {
        id: welcomeTimer
        interval: Theme.island.welcome
        onTriggered: root.welcomeShown = false
    }

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
        interval: root.reloadError ? Theme.island.reloadError : Theme.island.reloaded
        onTriggered: root.reloadShown = false
    }

    // Quick settings on one of its pages, or the today menu on one of its parts, on `screen`.
    function openPage(page: string, screen: string): void {
        screenName = screen;
        panel = "settings";
        quickPage = page;
    }
    function openToday(part: string, screen: string): void {
        screenName = screen;
        panel = "today";
        todayPart = part;
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
            // Background apps is a page of quick settings now, emoji a mode of the launcher.
            if (panel === "tray") {
                page("apps");
                return;
            }
            if (panel === "emoji") {
                LauncherState.showEmoji();
                return;
            }
            root.toggle(panel, Hyprland.focusedMonitor?.name ?? "");
        }

        function close(): void {
            root.panel = "";
        }

        // What decides whether a notification pops up, as one line of JSON, to check a pop-up that
        // didn't show without reloading the shell (which would reset it): the menu open, the
        // lock, the greeting, the reload notice, the queue, and the quiet reasons.
        function state(): string {
            return JSON.stringify({
                panel: root.panel,
                panelScreen: root.screenName,
                focusedScreen: Hyprland.focusedMonitor?.name ?? null,
                locked: Session.locked,
                ending: Session.ending,
                welcome: root.welcomeShown,
                reloadNotice: root.reloadShown,
                current: Notifications.current ? (Notifications.appOf(Notifications.current) + ": " + Notifications.current.summary) : null,
                queue: Notifications.queue.length,
                quiet: Notifications.quiet,
                doNotDisturb: Notifications.doNotDisturb,
                gameMode: GameMode.on,
                fullscreen: Notifications.fullscreenNow
            });
        }

        // Quick settings on one of its pages: qs ipc call island page system (Ctrl+Shift+Esc, the
        // task manager) or apps (background apps).
        function page(name: string): void {
            root.openPage(name, Hyprland.focusedMonitor?.name ?? "");
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

    // One island per monitor: Variants creates a delegate for each entry in the model
    // and destroys it when the monitor goes away.
    Variants {
        model: Quickshell.screens

        IslandWindow {
            island: root
        }
    }
}
