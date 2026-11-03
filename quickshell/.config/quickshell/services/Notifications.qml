// The notification server: Quickshell receives every app's notifications (there's no other
// notification daemon). New ones queue up as pop-ups, shown one at a time out of the island (bar/IslandWindow.qml), and
// stay in the history (the "today" menu) until dismissed. Do Not Disturb skips the pop-ups,
// except critical ones; the history still collects everything. With a schedule (settings
// window) it turns on at the start time and off at the end time; toggling in between lasts
// until the next of those, like night light. Game mode and a fullscreen window hold the pop-ups
// back the same way; afterwards one notification says how many came in meanwhile.
// Each app can be silent (never pops up) or always pop up, even then (Settings -> Notifications,
// NotificationRules.js).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "NotificationRules.js" as Rules
import "Schedule.js" as Schedule

Singleton {
    id: root

    property bool doNotDisturb: scheduledDnd

    // Whether the schedule says on right now (false without a schedule).
    readonly property bool scheduledDnd: Settings.values.dndScheduled
        && Schedule.active(Schedule.minutesOf(clock.date), Settings.values.dndStart, Settings.values.dndEnd)
    // Assigning doNotDisturb (the tile) breaks its binding, so follow the schedule from here on.
    onScheduledDndChanged: doNotDisturb = scheduledDnd

    // Switched by hand, it stays through a shell reload (`ghost update` reloads it).
    onDoNotDisturbChanged: dnd.on = doNotDisturb

    PersistentProperties {
        id: dnd
        reloadableId: "doNotDisturb"

        property bool on: false

        onReloaded: {
            if (on !== root.doNotDisturb)
                root.doNotDisturb = on;
        }
    }

    // A window fullscreen on the focused screen (a game, a film): pop-ups wait like Do Not
    // Disturb (Settings' dndFullscreen, on by default; Hyprland's fullscreen 2, not maximized).
    readonly property bool fullscreenNow: Settings.values.dndFullscreen
        && (Hyprland.focusedMonitor?.activeWorkspace?.toplevels.values ?? []).some(t => t.lastIpcObject?.fullscreen === 2)
    // Pop-ups held back: Do Not Disturb, game mode or a fullscreen window.
    readonly property bool quiet: doNotDisturb || GameMode.on || fullscreenNow
    // How many were held back (apps set to Silent don't count): when the quiet ends, one
    // notification says so.
    property int missed: 0
    onQuietChanged: {
        if (quiet || missed === 0)
            return;
        send("Notifications", "notifications", missed === 1 ? "1 notification came in while you were busy"
                                                            : missed + " notifications came in while you were busy",
             "They're in the today menu: click the time.", false, []);
        missed = 0;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Pop-ups still to show, oldest first. A notification closed meanwhile (dismissed, clicked,
    // closed by its app) leaves when it closes (onNotification): a destroyed one only turned into
    // null here without the list changing, so the corner kept an empty card. Readers still skip
    // nulls, in case.
    property list<Notification> queue: []

    // Newest first.
    readonly property list<Notification> history: server.trackedNotifications.values.slice().reverse()

    // When each notification arrived (ms since the epoch), by id: notifications carry no time.
    // Kept across a shell reload (the notifications are), as JSON text (NOTES.md), and only for
    // notifications still in the history.
    property var received: ({})

    function stamp(id: int): void {
        const kept = new Set(server.trackedNotifications.values.map(n => String(n.id)));
        const next = {};
        for (const key in received)
            if (kept.has(key))
                next[key] = received[key];
        next[id] = Date.now();
        received = next;
        times.json = JSON.stringify(next);
    }

    PersistentProperties {
        id: times
        reloadableId: "notificationTimes"

        property string json: ""

        onReloaded: {
            if (json !== "")
                root.received = JSON.parse(json);
        }
    }

    // The pop-up the island shows (bar/IslandWindow.qml), the oldest; the rest wait their turn.
    readonly property Notification current: queue.find(n => n !== null) ?? null

    // A pop-up is done (timed out, dismissed or clicked).
    function done(notification: Notification): void {
        queue = queue.filter(n => n !== null && n !== notification);
        // Transient notifications are meant for the pop-up only, not the history.
        if (notification?.transient)
            notification.expire();
    }

    // Sends a notification from the shell itself, through notify-send, so it arrives like any
    // app's (pop-up, history, per-app rules, sound). Each call runs on its own: two alerts in a row
    // both arrive. `hints`: extra notify-send hints, e.g. ["boolean:suppress-sound:true"].
    function send(app: string, icon: string, summary: string, body: string, critical: bool, hints: var): void {
        Quickshell.execDetached(["notify-send", "--app-name=" + app, "--icon=" + icon,
                                 "--urgency=" + (critical ? "critical" : "normal"),
                                 ...(hints ?? []).map(h => "--hint=" + h), summary, body]);
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
            root.stamp(notification.id);
            const critical = notification.urgency === NotificationUrgency.Critical;
            // Only once settings.json is in: writing to the defaults before then would save
            // them over the user's file.
            const apps = Settings.loaded ? Rules.remember(Settings.values.notificationApps, notification.appName) : null;
            if (apps !== null)
                Settings.values.notificationApps = apps;
            const mode = Rules.mode(Settings.values.notificationApps, notification.appName);
            if (Rules.popsUp(mode, root.quiet, critical)) {
                root.queue = [...root.queue, notification];
                notification.closed.connect(() => root.queue = root.queue.filter(n => n !== null && n !== notification));
                Sounds.playNotification(notification.hints, critical);
            } else if (mode !== "silent") {
                root.missed++;
            }
        }
    }
}
