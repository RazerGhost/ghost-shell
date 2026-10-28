import QtQuick
import Quickshell
import Quickshell.Io

// Keeps the login screen's copy of your settings, colors and lock screen picture up to date: runs
// greeter/sync.sh at startup and whenever one of those files changes (a setting, a new wallpaper,
// matugen's new colors). The script does nothing until update-greeter.sh has set things up.
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
        command: ["sh", Quickshell.shellDir + "/greeter/sync.sh"]
        onExited: code => {
            if (code !== 0)
                console.warn("LoginScreenSync: greeter/sync.sh exited with code " + code);
        }
    }

    // Variants, not Repeater: it creates any kind of object, not only visual items.
    Variants {
        model: ["settings.json", "colors.json", "wallpaper.json"]

        FileView {
            required property string modelData
            path: root.state + modelData
            watchChanges: true
            printErrors: false
            onFileChanged: debounce.restart()
        }
    }
}
