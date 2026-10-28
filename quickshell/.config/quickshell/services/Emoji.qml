// The emoji picker's data: every emoji from Unicode's list (the unicode-emoji package), the
// recently used ones, and putting one into the window you were in.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "EmojiData.js" as EmojiData

Singleton {
    id: root

    // [{ emoji, name, group }] in Unicode's order; empty until the list is read.
    readonly property var all: EmojiData.parse(list.text())
    // The most recently used first (the picker shows them before the rest).
    readonly property var recent: state.recent.map(e => all.find(a => a.emoji === e)).filter(e => e !== undefined)

    // Put the emoji into the window you were in, once the island has closed and the window has
    // the keyboard back. Terminals get it typed (they paste with Ctrl+Shift+V, not Ctrl+V).
    // Other apps get it pasted: Discord and other Electron/Chromium apps ignore emoji typed
    // through a virtual keyboard. The clipboard gets its old content back afterwards; both are
    // marked sensitive, so cliphist doesn't add them to the history.
    function type(emoji: string): void {
        state.recent = [emoji, ...state.recent.filter(e => e !== emoji)].slice(0, 24);
        recentFile.writeAdapter();
        const app = Windows.active?.wayland?.appId ?? "";
        const terminal = DesktopEntries.heuristicLookup(app)?.categories.includes("TerminalEmulator") ?? false;
        insert.command = terminal ? ["wtype", "--", emoji] : ["sh", "-c", root.pasteScript, "sh", emoji];
        insertLater.restart();
    }

    readonly property string pasteScript: `
        type=$(wl-paste --list-types 2>/dev/null | head -n 1)
        old=$(mktemp)
        [ -n "$type" ] && wl-paste --no-newline --type "$type" > "$old"
        printf %s "$1" | wl-copy --sensitive
        wtype -M ctrl v -m ctrl
        sleep 0.5 # let the app read the clipboard first
        [ -n "$type" ] && wl-copy --sensitive --type "$type" < "$old"
        rm -f "$old"
    `

    Process {
        id: insert
    }

    Timer {
        id: insertLater
        interval: 200 // the same wait as pasting from the clipboard menu
        onTriggered: insert.running = true
    }

    FileView {
        id: list
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        blockLoading: true // text() is read right away
    }

    FileView {
        id: recentFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/emoji.json"
        printErrors: false // missing until the first emoji is picked

        adapter: JsonAdapter {
            id: state
            property list<string> recent: []
        }
    }
}
