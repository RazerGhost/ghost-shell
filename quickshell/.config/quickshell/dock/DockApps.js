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
