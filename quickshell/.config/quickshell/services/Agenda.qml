// Calendar events for the today menu, from the calendars `ghost calendar add` subscribed to
// (modules/calendar/calendar.sh). Only once khal's config exists: then `vdirsyncer sync` runs
// at start and every 15 minutes, and khal lists the events of the month the calendar shows and
// the coming week. Parsing in CalendarEvents.js (tested). The links themselves are never read
// here.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "CalendarEvents.js" as CalendarEventsJs

Singleton {
    id: root

    readonly property bool enabled: khalConfig.loaded && khalConfig.text().includes("[[")
    // The month the today menu's calendar shows (0-11), for its event dots.
    property int year: clock.date.getFullYear()
    property int month: clock.date.getMonth()

    property var events: [] // [{ start, startTime, end, endTime, title, allDay }]
    // Why the calendars couldn't be updated ("" when they were). vdirsyncer's own message isn't
    // shown or logged: it can contain the link.
    property string error: ""
    readonly property var days: CalendarEventsJs.days(events) // dates with an event
    readonly property string today: CalendarEventsJs.iso(clock.date)
    readonly property var upcoming: CalendarEventsJs.upcoming(events, today, 4)
    // From `today` (text, so it only changes once a day), not the clock: a range built from the
    // minute clock is a new object every minute, which counted as a change and ran khal each time.
    readonly property var range: CalendarEventsJs.range(new Date(today + "T00:00"), year, month)

    // When an event is: "Today 14:00", "Tomorrow", "Mon 2 Nov 09:30" (English day names, like
    // the today menu's date; see the calendar locale decision). All-day ones without a time.
    function when(event: var): string {
        const day = new Date(event.start + "T00:00");
        // A calendar day after today: adding 24 hours misses on the nights the clocks change.
        const tomorrow = new Date(today + "T00:00");
        tomorrow.setDate(tomorrow.getDate() + 1);
        const label = event.start <= today ? "Today"
                    : event.start === Qt.formatDate(tomorrow, "yyyy-MM-dd") ? "Tomorrow"
                    : day.toLocaleDateString(Qt.locale(Qt.uiLanguage), "ddd d MMM");
        return event.allDay || event.start < today ? label : label + " " + event.startTime;
    }

    function refresh(): void {
        if (enabled)
            list.start();
    }

    onRangeChanged: refresh()
    onEnabledChanged: {
        if (enabled) {
            sync.running = true;
        } else {
            events = [];
            error = "";
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FileView {
        id: khalConfig
        path: Quickshell.env("HOME") + "/.config/khal/config"
        watchChanges: true
        printErrors: false // missing until a calendar is added
        onFileChanged: reload()
    }

    Timer {
        interval: 15 * 60 * 1000
        running: root.enabled
        repeat: true
        onTriggered: sync.running = true
    }

    Process {
        id: sync
        command: ["vdirsyncer", "sync"]
        onExited: code => {
            root.error = code === 0 ? "" : "Couldn't update the calendar (offline, or the link no longer works)";
            root.refresh();
        }
    }

    // Asked again while it runs (the month flipped, a sync finished), khal runs once more after,
    // so the shown month never keeps the last range's events.
    LatestProcess {
        id: list
        command: ["khal", "list", "--format", CalendarEventsJs.format, "--day-format", "", root.range.from, root.range.to]
        stdout: StdioCollector {
            onStreamFinished: root.events = CalendarEventsJs.parse(text)
        }
    }
}
