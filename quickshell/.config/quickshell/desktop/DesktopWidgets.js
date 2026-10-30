// Where the desktop widgets sit (desktop/DesktopWidgets.qml): each one's top-left corner as a
// fraction of the screen, so a place survives a resolution or scale change. Plain JavaScript,
// so it can be tested on its own (tests/tst_desktopwidgets.qml).
.pragma library

// Every widget: its name (its key in desktopWidgets, DesktopCard's `name`), the setting that
// turns it on, and whether it's medium (twice as wide) or small. The desktop editor's Cancel,
// themes and widget layouts take their keys from here; adding a widget also means its card in
// DesktopWidgets.qml, its setting and the editor's gallery.
const kinds = [
    { name: "clock",    key: "desktopClock",    medium: true },
    { name: "weather",  key: "desktopWeather",  medium: false },
    { name: "media",    key: "desktopMedia",    medium: true },
    { name: "calendar", key: "desktopCalendar", medium: true },
    { name: "battery",  key: "desktopBattery",  medium: false },
    { name: "todo",     key: "desktopTodo",     medium: true },
    { name: "timer",    key: "desktopTimer",    medium: false }
];
const keys = kinds.map(k => k.key);

// Two columns down the left side, under the island's height, until moved (the second one
// clear of a medium widget in the first on a 1920 px screen).
const defaults = {
    clock:    { x: 0.04, y: 0.08 },
    weather:  { x: 0.04, y: 0.26 },
    media:    { x: 0.04, y: 0.44 },
    calendar: { x: 0.24, y: 0.08 },
    battery:  { x: 0.24, y: 0.26 },
    todo:     { x: 0.24, y: 0.44 },
    timer:    { x: 0.34, y: 0.26 }
};

function fraction(value, fallback) {
    return typeof value === "number" && value >= 0 && value <= 1 ? value : fallback;
}

// The saved place of `name` from settings' desktopWidgets, else its default. A hand-edited
// value outside the screen falls back too.
function place(saved, name) {
    const fallback = defaults[name] ?? { x: 0, y: 0 };
    const own = saved?.[name];
    return { x: fraction(own?.x, fallback.x), y: fraction(own?.y, fallback.y) };
}

// A widget dropped at (x, y) px, w x h px, on a screen sw x sh px: its place as fractions,
// kept wholly on the screen.
function dropped(x, y, w, h, sw, sh) {
    const clamp = (v, max) => Math.min(Math.max(v, 0), Math.max(max, 0));
    return { x: clamp(x, sw - w) / sw, y: clamp(y, sh - h) / sh };
}

// The saved places with `name` at `place`, as a new object (so the setting's change is seen
// and saved); the others' places stay.
function withPlace(saved, name, place) {
    const places = JSON.parse(JSON.stringify(saved ?? {}));
    places[name] = { x: place.x, y: place.y };
    return places;
}

// A widget dropped at (x, y), w x h px, on a sw x sh screen, lines up with what's near it: the
// screen's edges at `margin`, and the other widgets (rects { x, y, w, h }) by their edges or
// right next to them at `gap`, when within `reach` px. Each axis on its own; {x, y} in px.
function snapped(x, y, w, h, sw, sh, others, margin, gap, reach) {
    const nearest = (value, targets) => {
        let best = value, distance = reach + 1;
        for (const t of targets) {
            const d = Math.abs(value - t);
            if (d <= reach && d < distance) {
                best = t;
                distance = d;
            }
        }
        return best;
    };
    const xs = [margin, sw - margin - w];
    const ys = [margin, sh - margin - h];
    for (const o of others ?? []) {
        xs.push(o.x, o.x + o.w - w, o.x + o.w + gap, o.x - gap - w);
        ys.push(o.y, o.y + o.h - h, o.y + o.h + gap, o.y - gap - h);
    }
    return { x: nearest(x, xs), y: nearest(y, ys) };
}

// The desktop grid (Settings' desktopGrid, desktopGridSize; the desktop editor's Places tile):
// lines every `cell` px out from the screen's middle, so whatever lines up on one side has its
// mirror image on the other. The positions of the lines across a side `size` px long.
const gridSizes = [16, 24, 32, 48, 64]; // px at 100 %

// The saved grid size if it's one of those, else 32.
function gridSize(saved) {
    return gridSizes.includes(saved) ? saved : 32;
}

function gridLines(size, cell) {
    if (!(cell > 0) || !(size > 0))
        return [];
    const middle = size / 2;
    const lines = [middle];
    for (let k = 1; middle - k * cell >= 0; k++)
        lines.push(middle - k * cell, middle + k * cell);
    return lines.sort((a, b) => a - b);
}

// A widget dropped at (x, y), w x h px, on a sw x sh screen, lined up with the grid: on each axis
// whichever of its start, middle or end is nearest a line moves onto it (so a medium widget can
// center on the middle line and a small one sit beside it), then it's kept on the screen.
function gridSnapped(x, y, w, h, sw, sh, cell) {
    const axis = (start, length, size) => {
        let best = start, distance = Infinity;
        for (const line of gridLines(size, cell))
            for (const offset of [0, length / 2, length]) {
                const d = Math.abs(start + offset - line);
                if (d < distance) {
                    distance = d;
                    best = line - offset;
                }
            }
        return Math.min(Math.max(best, 0), Math.max(size - length, 0));
    };
    return { x: axis(x, w, sw), y: axis(y, h, sh) };
}
