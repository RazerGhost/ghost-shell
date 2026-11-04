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
// (`fields`: rects, or one: the island with the password field, the message line; `gap` around
// each): where it would cover one, it stops just above, or under it when there's no room above.
function clamped(rect, dx, dy, sw, sh, fields, margin, gap) {
    const within = (v, low, high) => Math.min(Math.max(v, low), Math.max(low, high));
    const x = within(rect.x + dx, margin, sw - margin - rect.width);
    let y = within(rect.y + dy, margin, sh - margin - rect.height);
    // Lowest first: stopping above one can bring it onto one higher up.
    const list = (Array.isArray(fields) ? fields : [fields]).slice().sort((a, b) => b.y - a.y);
    for (const field of list) {
        const across = x < field.x + field.width + gap && x + rect.width > field.x - gap;
        const below = y + rect.height > field.y - gap && y < field.y + field.height + gap;
        if (!across || !below)
            continue;
        // Above it when there's room (none above the island at the top), else under it.
        const above = field.y - gap - rect.height;
        y = above >= margin ? above : Math.min(field.y + field.height + gap, sh - margin - rect.height);
    }
    return { x: x - rect.x, y: y - rect.y };
}

// Where each part of the lock screen was dragged (Settings' lockPlaces: { clock: { x, y }, date,
// player, weather, ... }, fractions of the screen), each on its own. Before lockPlaces
// there were two moves: the clock's (lockClockOffset, for the clock and the date) and the
// widgets' (lockWidgetsOffset, for the player and each widget); `values` (the settings) gives
// those while lockPlaces isn't set.
function placeOf(places, name, values) {
    if (places !== null && typeof places === "object" && !Array.isArray(places))
        return offset(places[name]);
    return offset(name === "clock" || name === "date" ? values?.lockClockOffset : values?.lockWidgetsOffset);
}

// The picture's quieter side (Settings' lockQuietSide): `text` its grey levels (0-255) as `od`
// prints them, `w` x `h` pixels row by row (LockContent has ffmpeg make that small copy). How
// busy each outer third is: the mean difference between a pixel and its right and lower
// neighbours (Ryoku's wallpaper tone map measures the same). "left" or "right" when one third is
// clearly calmer (the other at least 1.5 times as busy, and by more than a trace), else "" (a
// calm or evenly busy picture, or output that isn't the picture: nothing moves then).
function quietSide(text, w, h) {
    const greys = String(text).trim().split(/\s+/).map(Number);
    if (!(w >= 3 && h >= 2) || greys.length !== w * h || greys.some(v => !(v >= 0 && v <= 255)))
        return "";
    const third = Math.floor(w / 3);
    const busy = (from, to) => {
        let sum = 0, count = 0;
        for (let y = 0; y < h - 1; y++)
            for (let x = from; x < to && x < w - 1; x++) {
                const v = greys[y * w + x];
                sum += Math.abs(v - greys[y * w + x + 1]) + Math.abs(v - greys[(y + 1) * w + x]);
                count++;
            }
        return count > 0 ? sum / count : 0;
    };
    const left = busy(0, third);
    const right = busy(w - third, w);
    if (right >= left * 1.5 && right - left > 2)
        return "left";
    if (left >= right * 1.5 && left - right > 2)
        return "right";
    return "";
}

// Which side of a screen `width` px wide a part centred at `center` px is on: "" in the middle
// fifth.
function sideOf(center, width) {
    if (center < width * 0.4)
        return "left";
    if (center > width * 0.6)
        return "right";
    return "";
}

// The move that mirrors a part across the screen's middle: laid out at `x` px, `width` wide,
// moved `dx` px, on a screen `screenWidth` wide; it ends up as far from the other edge.
function mirroredMove(x, width, dx, screenWidth) {
    return screenWidth - 2 * x - width - dx;
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
