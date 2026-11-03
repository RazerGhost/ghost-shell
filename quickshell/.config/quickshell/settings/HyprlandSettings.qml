import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "HyprlandConfig.js" as HyprlandConfig

// Applies the settings that are Hyprland options (keyboard, touchpad, pointer, gaps, borders,
// corners, animation styles, apps reopening where they were) and game mode's overrides: writes ~/.config/hypr/shell-settings.lua, which hyprland.lua
// loads last, and reloads Hyprland. Only when the file's content changes, so starting the shell
// doesn't reload Hyprland. The login screen gets a copy too (greeter/sync.sh).
Scope {
    id: root

    readonly property bool bell: Settings.values.soundEvents && Settings.values.soundNotifications
                                 && !Notifications.doNotDisturb && !GameMode.on
    readonly property string text: HyprlandConfig.lua(Settings.values, GameMode.on, Wallpaper.path !== "", bell)
        + (HyprlandRuntime.lua ? "\n-- While the windows editor is open (services/HyprlandRuntime.qml).\n" + HyprlandRuntime.lua + "\n" : "")

    // Not before the wallpaper's file is read either: a moment without it would write Hyprland's
    // own picture back on, and reload Hyprland, at every start.
    onTextChanged: {
        if (Settings.loaded && Wallpaper.loaded)
            writeLater.restart();
    }

    Connections {
        target: Settings

        // Also the pointer: its value may have arrived with the file, before `loaded`.
        function onLoadedChanged(): void {
            if (Settings.loaded) {
                if (Wallpaper.loaded)
                    writeLater.restart();
                setCursor.restart();
            }
        }
    }

    // Both may be read before this exists (a reload).
    Component.onCompleted: {
        if (Settings.loaded && Wallpaper.loaded)
            writeLater.restart();
    }

    Connections {
        target: Wallpaper

        function onLoadedChanged(): void {
            if (Settings.loaded && Wallpaper.loaded)
                writeLater.restart();
        }
    }

    // A stepper clicked a few times in a row writes once.
    Timer {
        id: writeLater
        interval: 400
        onTriggered: {
            // The login screen's part, as data (HyprlandConfig.greeterData; greeter/sync.sh
            // copies it). Written first: the sync runs when shell-settings.lua changes.
            const forGreeter = HyprlandConfig.greeterData(Settings.values);
            if (greeterFile.text() !== forGreeter)
                greeterFile.setText(forGreeter);
            if (file.text() === root.text)
                return;
            file.setText(root.text);
            Quickshell.execDetached(["hyprctl", "reload"]);
        }
    }

    // The pointer changes at once with `hyprctl setcursor` (the file's variables only reach apps
    // started later); Hyprland also tells GTK (cursor.sync_gsettings_theme).
    readonly property string cursor: HyprlandConfig.cursorTheme(Settings.values.cursorTheme) + " "
                                     + HyprlandConfig.cursorSize(Settings.values.cursorSize)
    onCursorChanged: {
        if (Settings.loaded)
            setCursor.restart();
    }

    Timer {
        id: setCursor
        interval: 400
        onTriggered: Quickshell.execDetached(["hyprctl", "setcursor", ...root.cursor.split(/ (?=\d+$)/)])
    }

    FileView {
        id: greeterFile
        path: Quickshell.env("HOME") + "/.config/hypr/greeter-settings"
        blockLoading: true
        blockWrites: true
        printErrors: false
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/hypr/shell-settings.lua"
        blockLoading: true // compared with right away
        // Written before `hyprctl reload` runs: in the background the reload could read the old
        // file, and the change only applied at the next one.
        blockWrites: true
        printErrors: false // missing until the first write
    }
}
