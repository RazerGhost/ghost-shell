import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "HyprlandConfig.js" as HyprlandConfig

// Applies the settings that are Hyprland options (keyboard, touchpad, gaps, borders, corners,
// apps reopening where they were): writes ~/.config/hypr/shell-settings.lua, which hyprland.lua
// loads last, and reloads Hyprland. Only when the file's content changes, so starting the shell
// doesn't reload Hyprland. The login screen gets a copy too (greeter/sync.sh).
Scope {
    id: root

    readonly property string text: HyprlandConfig.lua(Settings.values)

    onTextChanged: {
        if (Settings.loaded)
            writeLater.restart();
    }

    Connections {
        target: Settings

        function onLoadedChanged(): void {
            if (Settings.loaded)
                writeLater.restart();
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

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/hypr/shell-settings.lua"
        blockLoading: true // compared with right away
        printErrors: false // missing until the first write
    }
}
