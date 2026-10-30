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

    readonly property string text: HyprlandConfig.lua(Settings.values, GameMode.on)
        + (HyprlandRuntime.lua ? "\n-- While the windows editor is open (services/HyprlandRuntime.qml).\n" + HyprlandRuntime.lua + "\n" : "")

    onTextChanged: {
        if (Settings.loaded)
            writeLater.restart();
    }

    Connections {
        target: Settings

        // Also the pointer: its value may have arrived with the file, before `loaded`.
        function onLoadedChanged(): void {
            if (Settings.loaded) {
                writeLater.restart();
                setCursor.restart();
            }
        }
    }

    // A stepper clicked a few times in a row writes once.
    Timer {
        id: writeLater
        interval: 400
        onTriggered: {
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
        id: file
        path: Quickshell.env("HOME") + "/.config/hypr/shell-settings.lua"
        blockLoading: true // compared with right away
        printErrors: false // missing until the first write
    }
}
