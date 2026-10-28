import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Keeps the login screen's copy of your settings, colors and lock screen picture up to date: runs
// greeter/sync.sh at startup and whenever one of those files changes (a setting, a new wallpaper,
// matugen's new colors). The script does nothing until `ghost greeter` has set things up.
Scope {
    id: root

    readonly property string state: Quickshell.env("HOME") + "/.local/state/quickshell/"

    // Changes often come in bursts (matugen writes colors right after a new wallpaper), so wait
    // a moment and sync once.
    Timer {
        id: debounce
        interval: 1000
        running: true // the first sync, at startup
        onTriggered: sync.running = true
    }

    Process {
        id: sync
        // The picture is passed in: Wallpaper.lockPath knows which one the lock screen shows.
        command: ["sh", Quickshell.shellDir + "/greeter/sync.sh", Wallpaper.lockPath]
        onExited: code => {
            if (code !== 0)
                console.warn("LoginScreenSync: greeter/sync.sh exited with code " + code);
        }
    }

    // Variants, not Repeater: it creates any kind of object, not only visual items.
    // The shell's state files, and the Hyprland settings it writes (keyboard layout).
    Variants {
        model: [root.state + "settings.json", root.state + "colors.json", root.state + "wallpaper.json",
                Quickshell.env("HOME") + "/.config/hypr/shell-settings.lua"]

        FileView {
            required property string modelData
            path: modelData
            watchChanges: true
            printErrors: false
            onFileChanged: debounce.restart()
        }
    }
}
