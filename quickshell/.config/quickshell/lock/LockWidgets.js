// Which widgets the lock screen shows (lock/LockStatus.qml), in your order (Settings'
// lockWidgets), picked in the lock screen editor; each can be placed on its own there. Plain JavaScript, so it can
// be tested on its own (tests/tst_lockwidgets.qml).
.pragma library

// Every one there is, in the order the editor offers them. The wide ones (the weather's and
// battery's wide versions, the event) are twice as wide as the others but count as one of the
// `most`.
const known = ["weather", "weatherWide", "battery", "batteryWide", "notifications", "todo", "timer", "event"];
const most = 4;

// Their names, for the editor and screen readers.
const names = { weather: "Weather", weatherWide: "Weather, wide", battery: "Battery", batteryWide: "Battery, wide",
                notifications: "Notifications", todo: "To-do", timer: "Timer", event: "Next event" };

// `list` without the battery's widgets on a machine without a battery.
function available(list, hasBattery) {
    return list.filter(id => hasBattery || !id.startsWith("battery"));
}

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

// `list` with `id` taken off, or added at the end while there's room.
function toggled(list, id) {
    if (list.includes(id))
        return list.filter(x => x !== id);
    return list.length < most && known.includes(id) ? [...list, id] : list.slice();
}
