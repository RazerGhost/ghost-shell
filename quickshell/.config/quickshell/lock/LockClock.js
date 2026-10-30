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
// place) kept on the screen (sw x sh, `margin` from the edges) and off the password field
// (`field`'s rect, `gap` around it): where it would cover the field, it stops just above it.
function clamped(rect, dx, dy, sw, sh, field, margin, gap) {
    const within = (v, low, high) => Math.min(Math.max(v, low), Math.max(low, high));
    const x = within(rect.x + dx, margin, sw - margin - rect.width);
    let y = within(rect.y + dy, margin, sh - margin - rect.height);
    const across = x < field.x + field.width + gap && x + rect.width > field.x - gap;
    const below = y + rect.height > field.y - gap && y < field.y + field.height + gap;
    if (across && below)
        y = Math.max(margin, field.y - gap - rect.height);
    return { x: x - rect.x, y: y - rect.y };
}
