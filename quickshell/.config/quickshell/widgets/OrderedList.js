// Moving items within a list you put in order: quick settings' tiles and buttons
// (controlcenter/QuickSettings.qml) and the dock's pins (dock/Dock.qml). Plain JavaScript, so it
// can be tested on its own (tests/tst_orderedlist.qml).
.pragma library

// `list` with the item at `from` moved to `to` (clamped into the list); the same list when
// `from` isn't in it.
function moved(list, from, to) {
    const out = Array.from(list);
    if (from < 0 || from >= out.length)
        return out;
    const [item] = out.splice(from, 1);
    out.splice(Math.max(0, Math.min(to, out.length)), 0, item);
    return out;
}

// `list` with `item` (in it already or not) put at `index` among the others, clamped.
function placed(list, item, index) {
    const out = Array.from(list).filter(x => x !== item);
    out.splice(Math.max(0, Math.min(index, out.length)), 0, item);
    return out;
}
