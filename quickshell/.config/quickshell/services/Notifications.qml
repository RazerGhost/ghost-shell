// The notification server: Quickshell receives every app's notifications (there's no other
// notification daemon). New ones queue up as pop-ups, shown one at a time by the island, and
// stay in the history (the "today" menu) until dismissed. Do Not Disturb skips the pop-ups,
// except critical ones; the history still collects everything. With a schedule (settings
// window) it turns on at the start time and off at the end time; toggling in between lasts
// until the next of those, like night light.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "Schedule.js" as Schedule

Singleton {
    id: root

    property bool doNotDisturb: scheduledDnd

    // Whether the schedule says on right now (false without a schedule).
    readonly property bool scheduledDnd: Settings.values.dndScheduled
        && Schedule.active(Schedule.minutesOf(clock.date), Settings.values.dndStart, Settings.values.dndEnd)
    // Assigning doNotDisturb (the tile) breaks its binding, so follow the schedule from here on.
    onScheduledDndChanged: doNotDisturb = scheduledDnd

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Pop-ups still to show, oldest first. A notification that's dismissed meanwhile turns
    // into null here (its object is destroyed), so readers skip nulls.
    property list<Notification> queue: []
    readonly property Notification current: queue.find(n => n !== null) ?? null

    // Newest first.
    readonly property list<Notification> history: server.trackedNotifications.values.slice().reverse()

    // When each notification arrived (ms since the epoch), by id: notifications carry no time.
    property var received: ({})

    // The current pop-up is done (timed out, dismissed or clicked).
    function next(): void {
        const done = current;
        queue = queue.filter(n => n !== null && n !== done);
        // Transient notifications are meant for the pop-up only, not the history.
        if (done?.transient)
            done.expire();
    }

    function clearAll(): void {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    // Clicking a notification: runs its default action (what clicking it means to the app, e.g.
    // open that chat) and switches to the app's window. The app can't take the focus itself
    // here (it would get an attention card instead), so the shell does it.
    function activate(n: Notification): void {
        const window = Windows.forApp(n.desktopEntry) ?? Windows.forApp(n.appName);
        n.actions.find(a => a.identifier === "default")?.invoke();
        n.dismiss();
        if (window)
            Windows.show(window);
    }

    NotificationServer {
        id: server

        // Keep notifications when the shell reloads (e.g. after editing a QML file).
        keepOnReload: true
        actionsSupported: true
        inlineReplySupported: true // chat apps can offer a reply field (NotificationCard)
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true; // keep it, or it's discarded right away
            // Notifications kept through a reload arrive again; they already popped up once.
            if (notification.lastGeneration)
                return;
            root.received[notification.id] = Date.now();
            const critical = notification.urgency === NotificationUrgency.Critical;
            if (!root.doNotDisturb || critical) {
                root.queue = [...root.queue, notification];
                Sounds.playNotification(notification.hints, critical);
            }
        }
    }
}
