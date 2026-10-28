// The today menu's notifications grouped by app (TodayPanel.qml). Plain JavaScript, so it can be
// tested on its own (tests/tst_notificationgroups.qml).
.pragma library

// `apps`: each notification's app name, newest first. Returns [{ app, indices }] (indices into
// `apps`, newest first), the groups ordered by their newest notification. Notifications without
// an app name are grouped as "".
function groups(apps) {
    const result = [];
    const byApp = new Map();
    apps.forEach((app, i) => {
        if (!byApp.has(app)) {
            byApp.set(app, { app: app, indices: [] });
            result.push(byApp.get(app));
        }
        byApp.get(app).indices.push(i);
    });
    return result;
}
