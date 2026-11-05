// Named looks for the on-screen editors (a gallery of picture cards, like the iOS lock screen
// gallery; the lock screen is the desktop, locked, so it has none of its own): picking one sets
// several settings at once; each can still be changed after. Plain JavaScript, so it can be
// tested on its own (tests/tst_presets.qml).
.pragma library
.import "../desktop/DesktopWidgets.js" as DesktopWidgets

// The desktop's style, over your wallpaper, accent and widgets: the glass, blur, corners and how
// the colors are drawn.
const desktop = [
    { name: "Ghost", values: { glass: true, glassOpacity: 45, blurStyle: "kawase", cornerScale: 1, colorStyle: "scheme-tonal-spot", colorContrast: 0 } },
    { name: "Frosted", values: { glass: true, glassOpacity: 30, blurStyle: "frost", cornerScale: 1.5, colorStyle: "scheme-vibrant", colorContrast: 0 } },
    { name: "Vivid", values: { glass: true, glassOpacity: 55, blurStyle: "acrylic", cornerScale: 1, colorStyle: "scheme-expressive", colorContrast: 0 } },
    { name: "Calm", values: { glass: true, glassOpacity: 60, blurStyle: "haze", cornerScale: 1.5, colorStyle: "scheme-neutral", colorContrast: -0.5 } },
    { name: "Solid", values: { glass: false, glassOpacity: 85, blurStyle: "kawase", cornerScale: 0.5, colorStyle: "scheme-tonal-spot", colorContrast: 0.5 } },
    { name: "Sharp", values: { glass: false, glassOpacity: 85, blurStyle: "kawase", cornerScale: 0, colorStyle: "scheme-monochrome", colorContrast: 0.5 } }
];

// Desktop widget layouts: a fitting set of widgets in groups, each group anchored to a part of the
// screen ("top-left", "center-right", "bottom-left", ...) and laid out in rows (a row's widgets
// side by side, 16 apart; rows lined up on the anchor's side), so a layout fits any screen size
// rather than one 1920 x 1080 picture. Laid out at 100 % (small widgets 168 px square, medium
// 352 x 168, large 352 square) clear of the island and the dock, and kept as fractions like a
// dragged widget's. All 13 widgets have a place in some layout; the to-do lists come in one size
// per layout (medium "todo" or large "tasks").
const widgetLayouts = [
    { name: "Clean", groups: [] },
    // The time and sky.
    { name: "Glance", groups: [{ anchor: "top-left", rows: [["clock", "weather"]] }] },
    // The time and a timer, what you're writing and what's left to do.
    { name: "Focus", groups: [{ anchor: "top-left", rows: [["clock", "timer"], ["note", "todo"]] }] },
    // The player at the bottom, the time above it, the sky beside it.
    { name: "Music", groups: [{ anchor: "bottom-left", rows: [["clock"], ["media", "weather"]] }] },
    // A column: the time, the day's events, tasks, and the sky and battery side by side.
    { name: "Workday", groups: [{ anchor: "center-right", rows: [["clock"], ["calendar"], ["todo"], ["weather", "battery"]] }] },
    // A planner: the time and the next hours' weather over the month and the to-do list.
    { name: "Planner", groups: [{ anchor: "center-right", rows: [["clock", "forecast"], ["month", "tasks"]] }] },
    // For writing: the time and sky, the note and the clipboard.
    { name: "Writer", groups: [{ anchor: "center-right", rows: [["clock", "weather"], ["note"], ["clipboard"]] }] },
    // A column: the time, the sky and battery, the player.
    { name: "Side", groups: [{ anchor: "center-left", rows: [["clock"], ["weather", "battery"], ["media"]] }] },
    // Nearly every widget (the large to-do list for both), in two blocks of the same size at the
    // top corners, keeping the middle and the lower half for the picture.
    { name: "Everything", groups: [
        { anchor: "top-left", rows: [["clock", "calendar"], ["media", "forecast"], ["weather", "battery", "timer", "notifications"]] },
        { anchor: "top-right", rows: [["month", "tasks"], ["note", "clipboard"]] }] }
];

// Room kept from the screen's edges by a layout: more than a dragged widget's (DesktopWidgets.unit)
// so a corner group sits clearly in its corner, less on a small screen where it wouldn't fit.
const layoutEdges = [{ side: 80, top: 80, bottom: 120 }, { side: DesktopWidgets.unit.side, top: DesktopWidgets.unit.top, bottom: DesktopWidgets.unit.bottom }];

// Where a layout's groups put their widgets on a sw x sh screen at 100 %, `mirror` swapping left
// and right: { name: { x, y } } in px, or null when it doesn't fit (off the screen, or groups
// overlapping). With the desktop grid on (`cell`, its spacing at 100 %), each group's outer edges
// go onto grid lines, the way a dropped widget lines up (DesktopWidgets.gridSnapped): a left
// group's left edge on the first line past the margin and a right group's right edge on the
// mirror of it, a top group's top edge on the first line below the island and a bottom group's
// bottom edge on the last above the dock, and a group in the middle of the height centered on the
// middle line. A preset then sits on the grid (a drag doesn't make it jump) and mirrored layouts
// mirror exactly.
function layoutPlaces(groups, sw, sh, mirror, cell) {
    const gap = DesktopWidgets.unit.gap;
    for (const edge of layoutEdges) {
        const places = {};
        const boxes = [];
        for (const group of groups) {
            let anchor = group.anchor;
            if (mirror)
                anchor = anchor.replace("left", "@").replace("right", "left").replace("@", "right");
            const [vertical, horizontal] = anchor.split("-");
            const rows = group.rows.map(row => {
                const sizes = row.map(n => DesktopWidgets.box(n));
                return { names: row, sizes: sizes, w: sizes.reduce((t, b) => t + b.w, 0) + gap * (row.length - 1),
                         h: Math.max(...sizes.map(b => b.h)) };
            });
            const gw = Math.max(...rows.map(r => r.w));
            const gh = rows.reduce((t, r) => t + r.h, 0) + gap * (rows.length - 1);
            let gx = horizontal === "left" ? edge.side : horizontal === "right" ? sw - edge.side - gw : (sw - gw) / 2;
            let gy = vertical === "top" ? edge.top : vertical === "bottom" ? sh - edge.bottom - gh
                   : edge.top + (sh - edge.top - edge.bottom - gh) / 2;
            if (cell > 0) {
                const xs = DesktopWidgets.gridLines(sw, cell), ys = DesktopWidgets.gridLines(sh, cell);
                const from = (lines, v) => lines.find(l => l >= v - 0.001);             // first line at or past v
                const upTo = (lines, v) => lines.slice().reverse().find(l => l <= v + 0.001); // last line at or before v
                if (horizontal === "left")
                    gx = from(xs, edge.side) ?? gx;
                else if (horizontal === "right")
                    gx = (upTo(xs, sw - edge.side) ?? gx + gw) - gw;
                if (vertical === "top")
                    gy = from(ys, edge.top) ?? gy;
                else if (vertical === "bottom")
                    gy = (upTo(ys, sh - edge.bottom) ?? gy + gh) - gh;
                else if (sh / 2 - gh / 2 >= edge.top && sh / 2 + gh / 2 <= sh - edge.bottom)
                    gy = sh / 2 - gh / 2;
            }
            boxes.push({ x: gx, y: gy, w: gw, h: gh });
            let y = gy;
            for (const row of rows) {
                let x = horizontal === "left" ? gx : horizontal === "right" ? gx + gw - row.w : gx + (gw - row.w) / 2;
                row.names.forEach((n, i) => {
                    places[n] = { x: x, y: y };
                    x += row.sizes[i].w + gap;
                });
                y += row.h + gap;
            }
        }
        const inside = boxes.every(b => b.x >= DesktopWidgets.unit.side && b.y >= DesktopWidgets.unit.top
                                      && b.x + b.w <= sw - DesktopWidgets.unit.side && b.y + b.h <= sh - DesktopWidgets.unit.bottom);
        const apart = boxes.every((a, i) => boxes.every((b, j) => i === j || a.x + a.w + gap <= b.x || b.x + b.w + gap <= a.x
                                                                    || a.y + a.h + gap <= b.y || b.y + b.h + gap <= a.y));
        if (inside && apart)
            return places;
    }
    return null;
}

// Which side a layout's groups sit on: "left", "right", or "" (both, or the middle).
function layoutSide(groups) {
    const sides = new Set(groups.map(g => g.anchor.endsWith("left") ? "left" : g.anchor.endsWith("right") ? "right" : ""));
    return sides.size === 1 ? [...sides][0] : "";
}

// A layout's settings: which widgets are on, and their places as fractions of the screen.
function layoutValues(places, sw, sh) {
    const values = {};
    const saved = {};
    for (const kind of DesktopWidgets.kinds) {
        values[kind.key] = kind.name in places;
        if (kind.name in places)
            // Six decimals: a thousandth of a pixel on a 4K screen, so a place on a grid line stays on it.
            saved[kind.name] = { x: Math.round(places[kind.name].x / sw * 1e6) / 1e6,
                                 y: Math.round(places[kind.name].y / sh * 1e6) / 1e6 };
    }
    values.desktopWidgets = saved;
    return values;
}

// The widget layouts for a sw x sh screen whose wallpaper is calmer on `quiet` ("left", "right"
// or "": DesktopWidgets.quietSide): a layout on one side moves to the calmer side, so the
// picture's subject stays clear. Layouts that don't fit the screen are left out. `cell`: the
// desktop grid's spacing at 100 % while it's on (layoutPlaces), else 0 or left out.
function widgetPresets(sw, sh, quiet, cell) {
    const presets = [];
    for (const layout of widgetLayouts) {
        const side = layoutSide(layout.groups);
        const places = layoutPlaces(layout.groups, sw, sh, quiet !== "" && side !== "" && side !== quiet, cell ?? 0);
        if (places)
            presets.push({ name: layout.name, values: layoutValues(places, sw, sh) });
    }
    return presets;
}

// On the laptop's 1920 x 1080 screen, as they read without a wallpaper to go around (the tests).
const desktopWidgets = widgetPresets(1920, 1080, "");

// The island and dock: how much the island shows and when and how large the dock is.
const dockIsland = [
    { name: "Ghost", values: { dockMode: "hide", dockIconSize: 44, workspaceDots: 5, hiddenStatusIcons: [], clockDate: false, clockSeconds: false, islandMedia: true } },
    { name: "Minimal", values: { dockMode: "hide", dockIconSize: 36, workspaceDots: 0, hiddenStatusIcons: ["bluetooth", "vpn", "updates", "timer"], clockDate: false, clockSeconds: false, islandMedia: false } },
    { name: "Desk", values: { dockMode: "always", dockIconSize: 52, workspaceDots: 5, hiddenStatusIcons: [], clockDate: true, clockSeconds: false, islandMedia: true } },
    { name: "Everything", values: { dockMode: "always", dockIconSize: 44, workspaceDots: 8, hiddenStatusIcons: [], clockDate: true, clockSeconds: true, islandMedia: false } }
];

// Windows: borders, corners, gaps and motion.
const windows = [
    { name: "Ghost", values: { borderSize: 2, rounding: 10, borderSpin: false, windowGlow: false, windowKindBorders: false, gapsIn: 5, gapsOut: 20, animationSpeed: 1, windowAnimation: "popin", workspaceAnimation: "fade", wobble: false } },
    { name: "Tight", values: { borderSize: 1, rounding: 4, borderSpin: false, windowGlow: false, windowKindBorders: false, gapsIn: 2, gapsOut: 6, animationSpeed: 1.5, windowAnimation: "slide", workspaceAnimation: "slide", wobble: false } },
    { name: "Spacious", values: { borderSize: 2, rounding: 16, borderSpin: false, windowGlow: true, windowKindBorders: false, gapsIn: 12, gapsOut: 32, animationSpeed: 1, windowAnimation: "popin", workspaceAnimation: "slidefade", wobble: false } },
    { name: "Playful", values: { borderSize: 3, rounding: 20, borderSpin: true, windowGlow: true, windowKindBorders: true, gapsIn: 8, gapsOut: 24, animationSpeed: 1, windowAnimation: "gnomed", workspaceAnimation: "slidevert", wobble: true } },
    { name: "Still", values: { borderSize: 1, rounding: 10, borderSpin: false, windowGlow: false, windowKindBorders: false, gapsIn: 5, gapsOut: 20, animationSpeed: 0, windowAnimation: "popin", workspaceAnimation: "fade", wobble: false } }
];

// Every setting the desktop editor changes, for its Cancel (the wallpaper is put back apart:
// it isn't a setting). Themes saved, renamed or deleted in it are put back too.
const desktopKeys = ["colorScheme", "colorStyle", "colorContrast", "accentColor",
                     ...DesktopWidgets.keys, "desktopWidgets", "desktopGrid", "desktopGridSize",
                     "glass", "glassOpacity", "blurStyle", "uiScale", "textScale", "cornerScale",
                     "fontSans", "fontMono", "iconTheme", "themes", "widgetLooks"];

// Every setting the dock and island editor changes, for its Cancel.
const dockIslandKeys = ["dockMode", "dockIconSize", "workspaceDots", "hiddenStatusIcons",
                        "clockDate", "clockSeconds", "islandMedia", "islandAttached", "dockLooks"];

// Every setting the windows editor changes, for its Cancel.
const windowsKeys = ["borderSize", "rounding", "borderSpin", "windowGlow", "windowKindBorders",
                     "gapsIn", "gapsOut", "animationSpeed", "windowAnimation", "workspaceAnimation", "wobble",
                     "windowLooks"];

// The values of `keys` now, to put back with restore() when an editor is cancelled.
function snapshot(values, keys) {
    const saved = {};
    for (const key of keys)
        saved[key] = values[key];
    return saved;
}

// Writes each saved value back explicitly (not by reloading an older file, which keeps any
// value whose key it lacks; see NOTES).
function restore(values, saved) {
    for (const key of Object.keys(saved))
        values[key] = saved[key];
}

// Whether two settings' values are the same: lists and objects by their contents, whatever the
// order of an object's keys (settings.json is written with them sorted, so the widgets' places
// come back in another order than a preset gave them), and unset counting as null.
// A list read back from settings.json isn't a JavaScript Array (NOTES): as one; anything else
// as it is.
function plain(value) {
    return value !== null && typeof value === "object" && typeof value.length === "number" && !Array.isArray(value)
        ? Array.from(value) : value;
}

function same(a, b) {
    a = plain(a ?? null);
    b = plain(b ?? null);
    if (a === b)
        return true;
    if (typeof a !== "object" || typeof b !== "object" || a === null || b === null)
        return false;
    if (Array.isArray(a) !== Array.isArray(b))
        return false;
    const keys = Object.keys(a);
    return keys.length === Object.keys(b).length && keys.every(k => Object.prototype.hasOwnProperty.call(b, k) && same(a[k], b[k]));
}

// The preset whose values all match the settings, else "" (a look of your own).
function current(values, presets) {
    const match = presets.find(p => Object.keys(p.values).every(k => same(values?.[k], p.values[k])));
    return match ? match.name : "";
}

// Sets a preset's values on `values` (Settings.values); unknown names change nothing.
function apply(values, presets, name) {
    const preset = presets.find(p => p.name === name);
    if (!preset)
        return;
    for (const key of Object.keys(preset.values))
        values[key] = JSON.parse(JSON.stringify(preset.values[key])); // a copy: lists stay the preset's
}
