import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/CalendarEvents.js" as CalendarEvents

TestCase {
    name: "CalendarEvents"

    function line(fields) {
        return fields.join(CalendarEvents.separator);
    }

    function test_range() {
        // Viewing this month: from its first day to the later of its end and a week from now.
        compare(CalendarEvents.range(new Date(2026, 9, 29), 2026, 9), { from: "2026-10-01", to: "2026-11-05" });
        // Viewing a later month: from today.
        compare(CalendarEvents.range(new Date(2026, 9, 29), 2026, 11), { from: "2026-10-29", to: "2026-12-31" });
        // Viewing an earlier month.
        compare(CalendarEvents.range(new Date(2026, 9, 29), 2026, 7), { from: "2026-08-01", to: "2026-11-05" });
    }

    function test_parse() {
        const text = [
            "",
            line(["2026-10-29", "14:00", "2026-10-29", "15:00", "Dentist"]),
            line(["2026-10-30", "", "2026-11-01", "", "Weekend away"]),
            line(["2026-10-30", "", "2026-11-01", "", "Weekend away"]), // listed again under the next day
            "Today, 2026-10-29",
            line(["nonsense", "", "", "", "x"])
        ].join("\n");
        const events = CalendarEvents.parse(text);
        compare(events.length, 2);
        compare(events[0], { start: "2026-10-29", startTime: "14:00", end: "2026-10-29", endTime: "15:00", title: "Dentist", allDay: false });
        verify(events[1].allDay);
    }

    function test_days() {
        const days = CalendarEvents.days([
            { start: "2026-10-30", end: "2026-11-01" },
            { start: "2026-10-29", end: "2026-10-29" }
        ]);
        compare(Object.keys(days).sort(), ["2026-10-29", "2026-10-30", "2026-10-31", "2026-11-01"]);
    }

    function test_upcoming() {
        const events = [
            { start: "2026-11-02", startTime: "09:00", end: "2026-11-02", title: "c" },
            { start: "2026-10-20", startTime: "", end: "2026-10-21", title: "past" },
            { start: "2026-10-28", startTime: "", end: "2026-10-30", title: "going on" },
            { start: "2026-11-02", startTime: "08:00", end: "2026-11-02", title: "b" }
        ];
        compare(CalendarEvents.upcoming(events, "2026-10-29", 5).map(e => e.title), ["going on", "b", "c"]);
        compare(CalendarEvents.upcoming(events, "2026-10-29", 1).length, 1);
    }

    function test_soon() {
        const events = [
            { start: "2026-11-04", startTime: "14:30", end: "2026-11-04", title: "later", allDay: false },
            { start: "2026-11-04", startTime: "14:10", end: "2026-11-04", title: "next", allDay: false },
            { start: "2026-11-04", startTime: "", end: "2026-11-04", title: "all day", allDay: true },
            { start: "2026-11-04", startTime: "13:50", end: "2026-11-04", title: "started", allDay: false }
        ];
        const now = new Date("2026-11-04T14:00:00");
        compare(CalendarEvents.soon(events, now, 15), { title: "next", minutes: 10 });
        compare(CalendarEvents.soon(events, now, 10).minutes, 10); // 10 minutes away is within 10
        compare(CalendarEvents.soon(events, now, 9), null);
        // Its last minute counts as 1; at its start it's no longer "up next".
        compare(CalendarEvents.soon(events, new Date("2026-11-04T14:09:30"), 15).minutes, 1);
        compare(CalendarEvents.soon(events, new Date("2026-11-04T14:10:00"), 25).title, "later");
        compare(CalendarEvents.soon([], now, 15), null);
    }
}
