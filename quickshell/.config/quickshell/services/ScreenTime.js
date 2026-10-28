// Screen time's numbers (services/ScreenTime.qml, settings/ScreenTimePage.qml): seconds of use
// per app per day, as { "2026-10-29": { "zen": 3600, ... } } with the days in local time, kept
// for 30 days. Plain JavaScript, so it can be tested on its own (tests/tst_screentime.qml).
.pragma library

const keepDays = 30;

// A Date as its local day, "2026-10-29".
function day(date) {
    const pad = n => String(n).padStart(2, "0");
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

// The data with `seconds` more for `app` on `dayKey`; only the newest 30 days stay.
function add(data, dayKey, app, seconds) {
    const result = Object.assign({}, data);
    result[dayKey] = Object.assign({}, result[dayKey]);
    result[dayKey][app] = (result[dayKey][app] ?? 0) + seconds;
    for (const old of Object.keys(result).sort().reverse().slice(keepDays))
        delete result[old];
    return result;
}

// A day's apps, most used first: [{ app, seconds }].
function apps(data, dayKey) {
    return Object.entries(data[dayKey] ?? {})
        .map(([app, seconds]) => ({ app: app, seconds: seconds }))
        .sort((a, b) => b.seconds - a.seconds);
}

function total(data, dayKey) {
    return Object.values(data[dayKey] ?? {}).reduce((sum, s) => sum + s, 0);
}

// The 7 days up to `today`, oldest first: [{ day, seconds }].
function week(data, today) {
    return Array.from({ length: 7 }, (_, i) => {
        const date = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6 + i);
        return { day: day(date), seconds: total(data, day(date)) };
    });
}

// "3 h 12 min", "12 min", "< 1 min".
function format(seconds) {
    const minutes = Math.floor(seconds / 60);
    if (minutes < 1)
        return "< 1 min";
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return h === 0 ? `${m} min` : m === 0 ? `${h} h` : `${h} h ${m} min`;
}
