// What the dock shows, for dock/Dock.qml. Plain JavaScript, so it can be tested on its own
// (tests/tst_dockapps.qml).
.pragma library

// The dock's items: pinned apps in the order they were pinned, then apps that are running but not
// pinned, in the order their first window appears. Each item is { id, pinned, windows }.
//   windows: the open windows, each with an `appId` (Wayland app id)
//   pinned:  desktop entry ids ("zen", "com.mitchellh.ghostty")
//   resolve: appId -> desktop entry id, or "" when no .desktop file matches; such apps get
//            the id "app:<appId>" so their windows still group together
function items(windows, pinned, resolve) {
    const byId = new Map();
    for (const id of pinned)
        byId.set(id, { id: id, pinned: true, windows: [] });
    for (const window of windows) {
        const id = resolve(window.appId) || "app:" + window.appId;
        if (!byId.has(id))
            byId.set(id, { id: id, pinned: false, windows: [] });
        byId.get(id).windows.push(window);
    }
    return [...byId.values()];
}

// Which window a click on an app's icon goes to, Windows-taskbar style:
//   - none open: "" (launch the app)
//   - the app has the focused window: the next of its windows (cycle), or "minimize" when it has
//     only one (clicking the active app's icon hides it)
//   - otherwise: its most recently used window
// `windows` are the app's windows, most recently used first; `focused` the focused one or null.
function clickTarget(windows, focused) {
    if (windows.length === 0)
        return "";
    const i = windows.indexOf(focused);
    if (i === -1)
        return windows[0];
    if (windows.length === 1)
        return "minimize";
    return windows[(i + 1) % windows.length];
}

// How many of `notifications` ([{ desktopEntry, appName }], the today menu's history) belong to
// the app with desktop entry `id` and name `name`: the dock's badge. Exact matches only (the
// notification's desktop entry, or its app name as the id or name): a fuzzy lookup once matched
// Vesktop to Pinentry.
function notificationCount(notifications, id, name) {
    const lower = s => (s || "").toLowerCase();
    return notifications.filter(n => lower(n.desktopEntry) === lower(id)
        || (n.appName && (lower(n.appName) === lower(id) || lower(n.appName) === lower(name)))).length;
}

// Where an app dragged along the dock lands (DockBar): its index among the other pinned apps,
// from where its middle is (`middle`, px in the dock's row) against theirs (`slots`, each
// { x, width } in the row, in order; an icon is `iconWidth` wide, at its slot's end). -1 when an
// app that isn't pinned is let go past the pinned ones: it stays unpinned.
function dropIndex(slots, middle, iconWidth, pinned) {
    const index = slots.filter(s => s.x + s.width - iconWidth / 2 < middle).length;
    const end = slots.reduce((last, s) => Math.max(last, s.x + s.width), 0);
    return pinned || middle < end + iconWidth / 2 ? index : -1;
}

// The pins with `id` moved `by` places (-1 left, 1 right); the same list when it can't move.
function movePin(pinned, id, by) {
    const list = Array.from(pinned);
    const from = list.indexOf(id);
    const to = from + by;
    if (from === -1 || to < 0 || to >= list.length)
        return list;
    list.splice(from, 1);
    list.splice(to, 0, id);
    return list;
}
