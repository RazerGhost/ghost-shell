// Daily schedules ("on from 20:00 until 07:00") for night light and Do Not Disturb. Times are
// minutes since midnight.
.pragma library

// Whether `now` falls inside the schedule: from `start` up to (not including) `end`. A schedule
// whose start is later than its end runs past midnight; start == end is never on.
function active(now, start, end) {
    if (start === end)
        return false;
    if (start < end)
        return now >= start && now < end;
    return now >= start || now < end;
}

// Minutes since midnight of a Date.
function minutesOf(date) {
    return date.getHours() * 60 + date.getMinutes();
}

// "07:30" for 450.
function format(minutes) {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0");
}

// Every quarter of an hour, the times a schedule can be set to.
const quarterHours = Array.from({ length: 96 }, (_, i) => i * 15);
