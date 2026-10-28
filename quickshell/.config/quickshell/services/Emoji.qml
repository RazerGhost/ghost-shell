// The emoji picker's data: every emoji from Unicode's list (the unicode-emoji package), the
// recently used ones, and typing one into the window you were in.
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

    // The island has closed; once the window has the keyboard back, type the emoji into it.
    // Typed, not pasted, so the clipboard keeps what you copied.
    function type(emoji: string): void {
        state.recent = [emoji, ...state.recent.filter(e => e !== emoji)].slice(0, 24);
        recentFile.writeAdapter();
        pending = emoji;
        typeLater.restart();
    }

    property string pending

    Timer {
        id: typeLater
        interval: 200 // the same wait as pasting from the clipboard menu
        onTriggered: Quickshell.execDetached(["wtype", "--", root.pending])
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
