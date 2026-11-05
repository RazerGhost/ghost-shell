// Where the desktop widgets sit (desktop/DesktopWidgets.qml): each one's top-left corner as a
// fraction of the screen, so a place survives a resolution or scale change. Plain JavaScript,
// so it can be tested on its own (tests/tst_desktopwidgets.qml).
.pragma library

// Every widget: its name (its key in desktopWidgets, DesktopCard's `name`), the setting that
// turns it on, and its size: small (a square), medium (twice as wide) or large (twice as wide
// and twice as tall, the month and the to-do list with room to add). The desktop editor's Cancel,
// themes and widget layouts take their keys from here; adding a widget also means its card in
// WidgetStage.qml, its regions in DesktopWidgets.qml, its setting and the editor's gallery.
const kinds = [
    { name: "clock",    key: "desktopClock", title: "Clock",    medium: true },
    { name: "weather",  key: "desktopWeather", title: "Weather",  medium: false },
    { name: "media",    key: "desktopMedia", title: "Media",    medium: true },
    { name: "calendar", key: "desktopCalendar", title: "Calendar", medium: true },
    { name: "battery",  key: "desktopBattery", title: "Battery",  medium: false },
    { name: "todo",     key: "desktopTodo", title: "To-do",     medium: true },
    { name: "timer",    key: "desktopTimer", title: "Timer",    medium: false },
    { name: "notifications", key: "desktopNotifications", title: "Notifications", medium: false },
    { name: "forecast", key: "desktopForecast", title: "Weather, hourly", medium: true },
    { name: "month",    key: "desktopMonth", title: "Month",    medium: true, large: true },
    { name: "tasks",    key: "desktopTasks", title: "To-do list",    medium: true, large: true },
    { name: "note",     key: "desktopNote", title: "Note",     medium: true },
    { name: "clipboard", key: "desktopClipboard", title: "Clipboard", medium: true }
];

// A widget's name for people (the editor's gallery, screen readers), by its settings key or name.
function title(keyOrName) {
    return kinds.find(k => k.key === keyOrName || k.name === keyOrName)?.title ?? keyOrName;
}
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
    timer:    { x: 0.34, y: 0.26 },
    notifications: { x: 0.04, y: 0.62 },
    forecast: { x: 0.48, y: 0.08 },
    month:    { x: 0.48, y: 0.26 },
    tasks:    { x: 0.68, y: 0.08 },
    note:     { x: 0.68, y: 0.44 },
    clipboard: { x: 0.68, y: 0.62 }
};

// A saved fraction may run a little past 0 and 1: at a smaller size the arrangement zooms toward
// the middle, so a widget against the edge there is stored past it (dropped()).
function fraction(value, fallback) {
    return typeof value === "number" && value >= -0.5 && value <= 1.5 ? value : fallback;
}

// The saved place of `name` from settings' desktopWidgets, else its default. A hand-edited
// value outside the screen falls back too.
function place(saved, name) {
    const fallback = defaults[name] ?? { x: 0, y: 0 };
    const own = saved?.[name];
    return { x: fraction(own?.x, fallback.x), y: fraction(own?.y, fallback.y) };
}

// Places are kept as they'd be at 100 % (the shell's and text's sizes, Theme.desktop.zoom). At
// another size the widgets are smaller or larger, so their places move toward or away from the
// screen's middle by the same factor: the whole arrangement zooms, and widgets laid out side
// by side stay side by side (with fractions alone, at 85 % the gaps between them stayed full
// size and a group spread apart).
function clamp(v, max) {
    return Math.min(Math.max(v, 0), Math.max(max, 0));
}

// Where a widget w x h px with the saved `place` shows on a sw x sh screen at `zoom`: {x, y}
// in px, kept wholly on the screen.
function shown(place, w, h, sw, sh, zoom) {
    const k = zoom > 0 ? zoom : 1;
    return { x: clamp(sw / 2 + (place.x * sw - sw / 2) * k, sw - w),
             y: clamp(sh / 2 + (place.y * sh - sh / 2) * k, sh - h) };
}

// Every widget showing, [{ name, x, y, w, h }] (x, y its saved place as fractions; w, h its size
// now), placed on a sw x sh screen at `zoom`: { name: { x, y } } in px. Widgets that sit
// together at 100 % (within `near` px) move as one group: zoomed around the middle, and a group
// that would run past an edge is shifted back as a whole, so its widgets keep their places
// against each other (each kept on the screen by itself, at a large size they piled up).
function arrange(items, sw, sh, zoom, near) {
    const k = zoom > 0 ? zoom : 1;
    const rects = items.map(i => {
        const x = i.x * sw, y = i.y * sh, w = i.w / k, h = i.h / k; // at 100 %
        return { name: i.name, x: x, y: y, w: w, h: h,
                 zx: sw / 2 + (x - sw / 2) * k, zy: sh / 2 + (y - sh / 2) * k, zw: i.w, zh: i.h };
    });
    // Groups: widgets closer than `near` to each other, and so on along.
    const group = rects.map((_, i) => i);
    const root = i => group[i] === i ? i : (group[i] = root(group[i]));
    const touch = (a, b) => a.x < b.x + b.w + near && b.x < a.x + a.w + near
                         && a.y < b.y + b.h + near && b.y < a.y + a.h + near;
    for (let i = 0; i < rects.length; i++)
        for (let j = i + 1; j < rects.length; j++)
            if (touch(rects[i], rects[j]))
                group[root(i)] = root(j);
    const shifts = {};
    rects.forEach((r, i) => {
        const g = root(i);
        const s = shifts[g] ?? (shifts[g] = { x0: Infinity, y0: Infinity, x1: -Infinity, y1: -Infinity });
        s.x0 = Math.min(s.x0, r.zx); s.y0 = Math.min(s.y0, r.zy);
        s.x1 = Math.max(s.x1, r.zx + r.zw); s.y1 = Math.max(s.y1, r.zy + r.zh);
    });
    // Back onto the screen: past the start edge first, else past the end edge.
    const back = (a, b, size) => a < 0 ? -a : b > size ? Math.max(size - b, -a) : 0;
    const placed = {};
    rects.forEach((r, i) => {
        const s = shifts[root(i)];
        placed[r.name] = { x: clamp(r.zx + back(s.x0, s.x1, sw), sw - r.zw), y: clamp(r.zy + back(s.y0, s.y1, sh), sh - r.zh) };
    });
    return placed;
}

// A widget dropped at (x, y) px, w x h px, on a screen sw x sh px at `zoom` (1 when left out):
// its place as fractions, as it would be at 100 %. Kept wholly on the screen as it shows now,
// not at 100 %: at 85 % the edge of the screen is past the 100 % screen's edge, and capping the
// fraction at 0 and 1 kept widgets about 7 % in from every edge (user's find, 2026-11-05).
function dropped(x, y, w, h, sw, sh, zoom) {
    const k = zoom > 0 ? zoom : 1;
    const at = (v, max, size) => (size / 2 + (clamp(v, max) - size / 2) / k) / size;
    return { x: at(x, sw - w, sw), y: at(y, sh - h, sh) };
}

// The saved places with `name` at `place`, as a new object (so the setting's change is seen
// and saved); the others' places stay.
function withPlace(saved, name, place) {
    const places = JSON.parse(JSON.stringify(saved ?? {}));
    places[name] = { x: place.x, y: place.y };
    return places;
}

// Sizes at 100 % (Theme.desktop scales these: a small widget's side, a medium one twice it plus
// the gap, a large one that square) and the room kept from the screen's edges: the island's band at the top (its
// Theme.island.reserved with room to spare), the dock's at the bottom.
const unit = { size: 168, gap: 16, side: 32, top: 80, bottom: 100 };

function box(name) {
    const kind = kinds.find(k => k.name === name);
    const wide = unit.size * 2 + unit.gap;
    return { w: kind?.medium ? wide : unit.size, h: kind?.large ? wide : unit.size };
}

// Places `name` as it's turned on (the desktop editor's gallery), clear of the widgets already
// showing (`others`, their names) on a sw x sh screen: at the place you last gave it if that's
// free, else next to one of them, lined up with its edges (beside it top or bottom aligned, below
// or above it left or right aligned), the spot that keeps the arrangement most compact (the
// smallest box around all of them); else the first free spot from the top left; where nothing is
// free, as it was. All at 100 % (places zoom with the size as a whole, so what's clear at 100 %
// stays clear). Returns the new desktopWidgets.
function freePlace(saved, name, others, sw, sh) {
    const size = box(name);
    const rects = others.map(n => {
        const p = place(saved, n);
        const b = box(n);
        return { x: p.x * sw, y: p.y * sh, w: b.w, h: b.h };
    });
    // A pixel of slack: saved places are rounded fractions, so a widget laid exactly one gap
    // from another comes back a hair closer.
    const gap = unit.gap - 1;
    const fits = c => c.x >= unit.side && c.y >= unit.top
        && c.x + size.w <= sw - unit.side && c.y + size.h <= sh - unit.bottom
        && rects.every(r => c.x + size.w + gap <= r.x || r.x + r.w + gap <= c.x
                         || c.y + size.h + gap <= r.y || r.y + r.h + gap <= c.y);
    const own = place(saved, name);
    const round = v => Math.round(v * 10000) / 10000;
    const ownSpot = { x: own.x * sw, y: own.y * sh };
    let spot = fits(ownSpot) ? ownSpot : null;
    if (!spot && rects.length > 0) {
        // Next to a widget, lined up with one of its edges; the most compact wins.
        const beside = [];
        for (const r of rects) {
            const right = r.x + r.w + unit.gap, left = r.x - unit.gap - size.w;
            const below = r.y + r.h + unit.gap, above = r.y - unit.gap - size.h;
            beside.push({ x: right, y: r.y }, { x: right, y: r.y + r.h - size.h },
                        { x: left, y: r.y }, { x: left, y: r.y + r.h - size.h },
                        { x: r.x, y: below }, { x: r.x + r.w - size.w, y: below },
                        { x: r.x, y: above }, { x: r.x + r.w - size.w, y: above });
        }
        const area = c => {
            const all = rects.concat([{ x: c.x, y: c.y, w: size.w, h: size.h }]);
            const x0 = Math.min(...all.map(r => r.x)), y0 = Math.min(...all.map(r => r.y));
            const x1 = Math.max(...all.map(r => r.x + r.w)), y1 = Math.max(...all.map(r => r.y + r.h));
            return (x1 - x0) * (y1 - y0);
        };
        let best = Infinity;
        for (const c of beside.filter(fits)) {
            const a = area(c);
            if (a < best) {
                best = a;
                spot = c;
            }
        }
    }
    if (!spot) {
        for (let y = unit.top; !spot && y + size.h <= sh - unit.bottom; y += unit.gap)
            for (let x = unit.side; x + size.w <= sw - unit.side; x += unit.gap)
                if (fits({ x: x, y: y })) {
                    spot = { x: x, y: y };
                    break;
                }
    }
    if (!spot)
        return saved ?? {};
    return withPlace(saved, name, { x: round(spot.x / sw), y: round(spot.y / sh) });
}

// The calmer side of a wallpaper, for placing widget layouts around the picture's subject
// (Presets.widgetPresets): `gray` is the picture shrunk to w x h grey values (0-255, row by row;
// services/Wallpaper.qml asks ffmpeg for 48 x 27). How busy each outer third is: the mean
// difference between neighbouring pixels. "left" or "right" when one is at least 1.5 times as
// calm as the other, else "" (evenly busy, or too little to tell).
function quietSide(gray, w, h) {
    if (!gray || gray.length < w * h || w < 6 || h < 2)
        return "";
    const third = Math.floor(w / 3);
    const busy = (from, to) => {
        let sum = 0, n = 0;
        for (let y = 0; y < h - 1; y++)
            for (let x = from; x < to - 1; x++) {
                const p = gray[y * w + x];
                sum += Math.abs(p - gray[y * w + x + 1]) + Math.abs(p - gray[(y + 1) * w + x]);
                n += 2;
            }
        return n > 0 ? sum / n : 0;
    };
    const left = busy(0, third), right = busy(w - third, w);
    if (right >= Math.max(left, 0.5) * 1.5)
        return "left";
    if (left >= Math.max(right, 0.5) * 1.5)
        return "right";
    return "";
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

// An arrow key's move ("left", "right", "up", "down"): one grid line (`cell` px) while the grid
// is on, else `step` px; { dx, dy }, or null for another key.
function keyStep(direction, cell, step) {
    const by = cell > 0 ? cell : step;
    return ({ left: { dx: -by, dy: 0 }, right: { dx: by, dy: 0 }, up: { dx: 0, dy: -by }, down: { dx: 0, dy: by } })[direction] ?? null;
}

// A widget w x h px at its saved `place` (fractions) on a sw x sh screen at `zoom`, moved
// (dx, dy) px with the keyboard (the desktop editor): onto the grid when it's on (`cell` px,
// else 0), kept on the screen; its new place as fractions.
function nudged(place, dx, dy, w, h, sw, sh, cell, zoom) {
    const from = shown(place, w, h, sw, sh, zoom);
    let x = from.x + dx, y = from.y + dy;
    if (cell > 0) {
        const at = gridSnapped(x, y, w, h, sw, sh, cell);
        // Snapping back to where it started would make a step do nothing: one more line along.
        x = Math.abs(at.x - from.x) < 0.5 && dx !== 0 ? at.x + Math.sign(dx) * cell : at.x;
        y = Math.abs(at.y - from.y) < 0.5 && dy !== 0 ? at.y + Math.sign(dy) * cell : at.y;
    }
    return dropped(x, y, w, h, sw, sh, zoom);
}

// Which screen widget `name` is on: the one saved with its place (a drop past a screen's edge
// moves it to the screen there) while that's connected, else the main screen, so a widget is
// never lost with its screen unplugged. `screens` the connected output names.
function screenOf(saved, name, screens, main) {
    const own = saved?.[name]?.screen;
    return typeof own === "string" && Array.from(screens ?? []).includes(own) ? own : main;
}

// The screen (`hyprctl monitors -j` entry) holding the point (x, y) in Hyprland's layout pixels,
// with the point in its own pixels: { name, x, y, w, h }; null when it's on none (between them).
function screenAt(monitors, x, y) {
    for (const m of Array.from(monitors ?? [])) {
        if (m.disabled)
            continue;
        const s = m.scale > 0 ? m.scale : 1;
        const w = (m.transform % 2 === 1 ? m.height : m.width) / s;
        const h = (m.transform % 2 === 1 ? m.width : m.height) / s;
        if (x >= m.x && x < m.x + w && y >= m.y && y < m.y + h)
            return { name: m.name, x: x - m.x, y: y - m.y, w: w, h: h };
    }
    return null;
}
