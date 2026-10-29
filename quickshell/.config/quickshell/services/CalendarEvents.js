// Calendar events for the today menu (services/Calendar.qml): the dates khal is asked for and
// its output. Plain JavaScript, so it can be tested on its own (tests/tst_calendarevents.qml).
// Dates are "YYYY-MM-DD" strings (khal's dateformat, set by modules/calendar/calendar.sh), which
// compare correctly as text.
.pragma library

// Fields of a `khal list --format` line, separated by this (unit separator: never in a title).
const separator = "\u001f";
const format = ["{start-date}", "{start-time}", "{end-date}", "{end-time}", "{title}"].join(separator);

function iso(date) {
    return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0") + "-" + String(date.getDate()).padStart(2, "0");
}

function addDays(date, days) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);
}

// What to ask khal for: the month the calendar shows (month 0-11) and the coming week, from
// whichever starts first to whichever ends last.
function range(today, year, month) {
    const monthStart = new Date(year, month, 1);
    const monthEnd = new Date(year, month + 1, 0);
    const weekEnd = addDays(today, 7);
    return {
        from: iso(monthStart < today ? monthStart : today),
        to: iso(monthEnd > weekEnd ? monthEnd : weekEnd)
    };
}

// khal's lines -> [{ start, startTime, end, endTime, title, allDay }]. khal lists an event that
// spans days under each day; those come back once. Lines that aren't events are skipped.
function parse(text) {
    const seen = new Set();
    const events = [];
    for (const line of text.split("\n")) {
        const f = line.split(separator);
        if (f.length !== 5 || !/^\d{4}-\d\d-\d\d$/.test(f[0]))
            continue;
        const key = f.join(separator);
        if (seen.has(key))
            continue;
        seen.add(key);
        events.push({ start: f[0], startTime: f[1], end: f[2] || f[0], endTime: f[3], title: f[4], allDay: f[1] === "" });
    }
    return events;
}

// The days that have an event (every day an event spans), as a set of dates.
function days(events) {
    const result = {};
    for (const e of events) {
        const [y, m, d] = e.start.split("-").map(Number);
        for (let day = new Date(y, m - 1, d), i = 0; iso(day) <= e.end && i < 366; day = addDays(day, 1), i++)
            result[iso(day)] = true;
    }
    return result;
}

// The events still to come or going on (ending today or later), by start, at most `limit`.
function upcoming(events, today, limit) {
    return events.filter(e => e.end >= today)
        .sort((a, b) => (a.start + a.startTime).localeCompare(b.start + b.startTime))
        .slice(0, limit);
}
