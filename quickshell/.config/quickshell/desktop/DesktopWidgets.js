// Where the desktop widgets sit (desktop/DesktopWidgets.qml): each one's top-left corner as a
// fraction of the screen, so a place survives a resolution or scale change. Plain JavaScript,
// so it can be tested on its own (tests/tst_desktopwidgets.qml).
.pragma library

// Down the left side, under the island's height, until moved.
const defaults = {
    clock:   { x: 0.04, y: 0.08 },
    weather: { x: 0.04, y: 0.32 },
    media:   { x: 0.04, y: 0.46 }
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
