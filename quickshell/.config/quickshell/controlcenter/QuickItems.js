// Which tiles and round buttons quick settings shows, in your order (Settings' quickTiles and
// quickToggles), edited on the panel itself (QuickSettings.qml's edit mode). Plain
// JavaScript, so it can be tested on its own (tests/tst_quickitems.qml).
.pragma library

// Every one there is, in the order they're offered; the defaults are what quick settings
// showed before it could be edited.
const tiles = ["wifi", "bluetooth", "sound", "power"];
const toggles = ["mic", "dnd", "nightlight", "awake", "game", "airplane", "dark", "record", "screenshot", "wallpaper",
                 "timer"];
const defaultTiles = ["wifi", "bluetooth", "sound", "power"];
const defaultToggles = ["mic", "dnd", "nightlight", "awake", "game"];

// A saved list made safe: known ids only, each once, in the saved order; the defaults when
// there's no list (a hand-edited file can't break the panel, and an empty list stays empty).
function shown(saved, known, defaults) {
    if (!Array.isArray(saved))
        return defaults.slice();
    const out = [];
    for (const id of saved)
        if (known.includes(id) && !out.includes(id))
            out.push(id);
    return out;
}

// The ones not shown, in the order they're offered: the edit mode's "Available".
function available(list, known) {
    return known.filter(id => !list.includes(id));
}

function removed(list, id) {
    return list.filter(x => x !== id);
}

function added(list, id) {
    return list.includes(id) ? list.slice() : [...list, id];
}
