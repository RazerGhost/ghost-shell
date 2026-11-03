// Clipboard history from cliphist (it records everything copied; see hypr/autostart.lua).
// Picking an entry copies it again and pastes it into the window you were in, like Windows'
// Win+V: wtype presses Ctrl+V once the island has closed and that window has the keyboard back.
// Pinned texts are kept apart from cliphist (~/.local/state/quickshell/clipboard-pins.json), so
// "Clear all" leaves them; the menu shows them first (ClipboardEntries.withPins, tested).
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

    // The pinned texts, oldest first.
    readonly property var pins: Array.from(pinState.texts ?? [])

    function refresh(): void {
        list.start();
    }

    // Copies `entry` (from the history, or a pin) and pastes it. Call after closing the menu.
    function paste(entry: var): void {
        copy.start(entry.pinned ? ["sh", "-c", 'printf %s "$1" | wl-copy', "sh", entry.text]
                                : ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
    }

    // Pins a text entry: its whole text (cliphist's list only has a shortened preview).
    function pin(entry: var): void {
        if (entry.image || entry.pinned)
            return;
        decodePin.start(["cliphist", "decode", entry.id]);
    }

    function unpin(text: string): void {
        pinState.texts = ClipboardEntries.unpin(pins, text);
        pinFile.writeAdapter();
    }

    // A pin made while the last one is still being decoded runs after it.
    LatestProcess {
        id: decodePin
        stdout: StdioCollector {
            onStreamFinished: {
                pinState.texts = ClipboardEntries.pin(root.pins, text);
                pinFile.writeAdapter();
            }
        }
    }

    FileView {
        id: pinFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/clipboard-pins.json"
        printErrors: false // missing until the first pin
        blockLoading: true // loaded before a pin is written over it

        adapter: JsonAdapter {
            id: pinState
            property var texts: []
        }
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

    // A pick while the last one still copies runs after it instead of being dropped.
    LatestProcess {
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
