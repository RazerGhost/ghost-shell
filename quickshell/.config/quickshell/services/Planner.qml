// The to-do list (the desktop's to-do widgets) and the today menu's note, kept in ~/.local/state/quickshell/today.json. Changes
// are written half a second after the last one (the note is saved while typing). List logic in
// Planner.js (tested).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Planner.js" as PlannerJs

Singleton {
    id: root

    // A JsonAdapter list isn't a JavaScript array (Array.isArray is false), hence Array.from.
    readonly property var todos: PlannerJs.valid(Array.from(state.todos ?? []))
    readonly property int open: todos.filter(t => !t.done).length
    readonly property string note: state.note

    function add(text: string): void {
        save(PlannerJs.add(todos, text));
    }

    function toggle(index: int): void {
        save(PlannerJs.toggle(todos, index));
    }

    function remove(index: int): void {
        save(PlannerJs.remove(todos, index));
    }

    function clearDone(): void {
        save(PlannerJs.clearDone(todos));
    }

    function setNote(text: string): void {
        if (text === state.note)
            return;
        state.note = text;
        writeLater.restart();
    }

    function save(list: var): void {
        state.todos = list;
        writeLater.restart();
    }

    Timer {
        id: writeLater
        interval: 500
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/today.json"
        printErrors: false // missing until the first task or note

        adapter: JsonAdapter {
            id: state
            property var todos: []
            property string note: ""
        }
    }
}
