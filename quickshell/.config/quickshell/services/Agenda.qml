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
    readonly property var days: CalendarEventsJs.days(events) // dates with an event
    readonly property string today: CalendarEventsJs.iso(clock.date)
    readonly property var upcoming: CalendarEventsJs.upcoming(events, today, 4)
    readonly property var range: CalendarEventsJs.range(clock.date, year, month)

    function refresh(): void {
        if (enabled)
            list.running = true;
    }

    onRangeChanged: refresh()
    onEnabledChanged: {
        if (enabled)
            sync.running = true;
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
        onExited: root.refresh()
    }

    Process {
        id: list
        command: ["khal", "list", "--format", CalendarEventsJs.format, "--day-format", "", root.range.from, root.range.to]
        stdout: StdioCollector {
            onStreamFinished: root.events = CalendarEventsJs.parse(text)
        }
    }
}
