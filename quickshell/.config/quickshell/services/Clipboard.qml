// Clipboard history from cliphist (it records everything copied; see hypr/autostart.lua).
// Picking an entry copies it again and pastes it into the window you were in, like Windows'
// Win+V: wtype presses Ctrl+V once the island has closed and that window has the keyboard back.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ClipboardEntries.js" as ClipboardEntries

Singleton {
    id: root

    // Parsed entries, newest first; see ClipboardEntries.parse.
    property var entries: []
    // Image entries are decoded into files here to show them as thumbnails.
    readonly property string thumbnailDir: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-clipboard"

    function refresh(): void {
        list.start();
    }

    // Copies `entry` and pastes it. Call after closing the menu.
    function paste(entry: var): void {
        copy.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id];
        copy.running = true;
    }

    function remove(entry: var): void {
        entries = entries.filter(e => e !== entry);
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line]);
    }

    function wipe(): void {
        entries = [];
        Quickshell.execDetached(["cliphist", "wipe"]);
    }

    LatestProcess {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.entries = ClipboardEntries.parseAll(text);
                } catch (e) {
                    console.warn("Clipboard: " + e.message);
                }
            }
        }
    }

    Process {
        id: copy
        onExited: pasteLater.start()
    }

    // The menu is closing and the window gets the keyboard back; wait for that.
    Timer {
        id: pasteLater
        interval: 200
        onTriggered: Quickshell.execDetached(["wtype", "-M", "ctrl", "v", "-m", "ctrl"])
    }
}
