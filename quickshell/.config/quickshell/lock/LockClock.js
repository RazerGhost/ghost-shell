// The lock and login screens' clock (Settings -> Lock screen -> Clock): its styles, sizes and
// where it sits. Plain JavaScript, so it can be tested on its own (tests/tst_lockclock.qml).
.pragma library

const styles = ["big", "stacked", "thin", "analog"];
const layouts = ["top", "center", "left"]; // left: the clock in the bottom-left corner
const sizes = [75, 100, 125, 150];         // percent of Theme.lock.clock

// One of `allowed`, else the first (the default): a hand-edited settings file can't hide the clock.
function pick(value, allowed) {
    return allowed.includes(value) ? value : allowed[0];
}

// The digits as text: { hours, minutes, suffix }; suffix is "AM"/"PM" with the 12-hour clock.
function digits(date, h24) {
    const h = date.getHours();
    const minutes = String(date.getMinutes()).padStart(2, "0");
    if (h24)
        return { hours: String(h).padStart(2, "0"), minutes, suffix: "" };
    return { hours: String(h % 12 || 12), minutes, suffix: h < 12 ? "AM" : "PM" };
}

// The analog clock's hands, in degrees clockwise from 12. The hour hand moves with the minutes.
function hands(date) {
    const m = date.getMinutes();
    return { hour: (date.getHours() % 12) * 30 + m / 2, minute: m * 6 };
}

// Where the clock and what's under it were dragged from their layout's place (Settings'
// lockClockOffset, the lock screen editor): { x, y } as fractions of the screen; nothing moved
// for anything else.
function offset(saved) {
    const ok = v => typeof v === "number" && v >= -1 && v <= 1;
    return saved && ok(saved.x) && ok(saved.y) ? { x: saved.x, y: saved.y } : { x: 0, y: 0 };
}

// The move (dx, dy, px) of the clock's column (`rect`: { x, y, width, height } at its layout's
// place) kept on the screen (sw x sh, `margin` from the edges) and off what must stay clear
// (`fields`: rects, or one: the password field with its hints, the login screen's power
// buttons, the message line; `gap` around each): where it would cover one, it stops just above.
function clamped(rect, dx, dy, sw, sh, fields, margin, gap) {
    const within = (v, low, high) => Math.min(Math.max(v, low), Math.max(low, high));
    const x = within(rect.x + dx, margin, sw - margin - rect.width);
    let y = within(rect.y + dy, margin, sh - margin - rect.height);
    // Lowest first: stopping above one can bring it onto one higher up.
    const list = (Array.isArray(fields) ? fields : [fields]).slice().sort((a, b) => b.y - a.y);
    for (const field of list) {
        const across = x < field.x + field.width + gap && x + rect.width > field.x - gap;
        const below = y + rect.height > field.y - gap && y < field.y + field.height + gap;
        if (across && below)
            y = Math.max(margin, field.y - gap - rect.height);
    }
    return { x: x - rect.x, y: y - rect.y };
}

// Where each part of the lock screen was dragged (Settings' lockPlaces: { clock: { x, y }, date,
// player, weather, ..., field }, fractions of the screen), each on its own. Before lockPlaces
// there were two moves: the clock's (lockClockOffset, for the clock and the date) and the
// widgets' (lockWidgetsOffset, for the player and each widget); `values` (the settings) gives
// those while lockPlaces isn't set.
function placeOf(places, name, values) {
    if (places !== null && typeof places === "object" && !Array.isArray(places))
        return offset(places[name]);
    if (name === "field")
        return offset(null);
    return offset(name === "clock" || name === "date" ? values?.lockClockOffset : values?.lockWidgetsOffset);
}

// The places with `name` at `place`: a new object (so the setting's change is seen). The first
// time, every part in `names` keeps where the old two moves had it.
function withPlace(places, name, place, values, names) {
    const out = {};
    for (const part of names) {
        const at = placeOf(places, part, values);
        if (at.x !== 0 || at.y !== 0)
            out[part] = at;
    }
    out[name] = { x: place.x, y: place.y };
    return out;
}
