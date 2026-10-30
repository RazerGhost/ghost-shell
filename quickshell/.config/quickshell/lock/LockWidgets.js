// Which widgets the lock screen shows in its row under the clock (lock/LockStatus.qml), in your
// order (Settings' lockWidgets), picked in the lock screen editor. Plain JavaScript, so it can
// be tested on its own (tests/tst_lockwidgets.qml).
.pragma library

// Every one there is, in the order the editor offers them; the event is wide (two places).
const known = ["weather", "battery", "notifications", "todo", "timer", "event"];
const most = 4;

// A saved list made safe: known ids only, each once, at most `most`. Without a list yet, the
// lines the lock screen showed before (its old switches, `values`), in their order.
function shown(saved, values) {
    if (!Array.isArray(saved)) {
        const old = [["weather", "lockWeather"], ["battery", "lockBattery"], ["event", "lockEvent"],
                     ["notifications", "lockNotificationCount"]];
        return old.filter(([, key]) => values?.[key] === true).map(([id]) => id);
    }
    const out = [];
    for (const id of saved)
        if (known.includes(id) && !out.includes(id) && out.length < most)
            out.push(id);
    return out;
}

// `list` with the widget at `from` moved to `to` (clamped into the list).
function moved(list, from, to) {
    const out = list.slice();
    if (from < 0 || from >= out.length)
        return out;
    const [id] = out.splice(from, 1);
    out.splice(Math.max(0, Math.min(to, out.length)), 0, id);
    return out;
}

// `list` with `id` taken off, or added at the end while there's room.
function toggled(list, id) {
    if (list.includes(id))
        return list.filter(x => x !== id);
    return list.length < most && known.includes(id) ? [...list, id] : list.slice();
}
