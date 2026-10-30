// Named looks for the on-screen editors (a gallery of picture cards, like the iOS lock screen
// gallery): picking one sets several settings at once; each can still be changed after. Plain JavaScript, so it can be tested on its own (tests/tst_presets.qml).
.pragma library
.import "../desktop/DesktopWidgets.js" as DesktopWidgets

// The lock and login screens: the clock's style, place, size and font, the picture's blur and
// darkening, and the widgets under the clock and where they sit (never the next event: its
// title would show to anyone at the screen).
const clockLook = (style, layout, size, font, blur, dim) => ({ lockClockStyle: style, lockLayout: layout, lockClockSize: size,
                                                              lockClockFont: font, lockBlur: blur, lockDim: dim });
const lock = [
    { name: "Classic", values: Object.assign(clockLook("big", "top", 100, "", 100, 25),
        { lockWidgets: ["weather", "battery", "notifications"], lockPlaces: null, lockClockOffset: null, lockWidgetsOffset: null }) },
    { name: "Minimal", values: Object.assign(clockLook("thin", "top", 100, "", 100, 40),
        { lockWidgets: [], lockPlaces: null, lockClockOffset: null, lockWidgetsOffset: null }) },
    { name: "Analog", values: Object.assign(clockLook("analog", "left", 100, "", 60, 30),
        { lockWidgets: ["weather", "notifications"], lockPlaces: null, lockClockOffset: null, lockWidgetsOffset: null }) },
    { name: "Bold", values: Object.assign(clockLook("stacked", "top", 125, "Inter Display", 100, 25),
        { lockWidgets: ["weather", "battery", "notifications", "todo"], lockPlaces: null, lockClockOffset: null, lockWidgetsOffset: null }) },
    // A serif clock in the bottom-left corner, like a magazine cover, the middle left to the art.
    { name: "Editorial", values: Object.assign(clockLook("big", "left", 125, "C059", 80, 35),
        { lockWidgets: ["weather"], lockPlaces: null, lockClockOffset: null, lockWidgetsOffset: null }) },
    // The clock in the bottom-left corner, the widgets apart from it to the right.
    { name: "Split", values: Object.assign(clockLook("big", "left", 100, "", 100, 30),
        { lockWidgets: ["weather", "battery", "notifications", "timer"], lockClockOffset: null, lockWidgetsOffset: null,
          lockPlaces: { player: { x: 0.6, y: 0 }, weather: { x: 0.6, y: 0 }, battery: { x: 0.6, y: 0 },
                        notifications: { x: 0.6, y: 0 }, timer: { x: 0.6, y: 0 } } }) },
    // Everything in one column on the left third (a thin clock, the date, the player and four
    // widgets), the rest of the picture left to the art; with the quiet side on, it moves to
    // whichever side is calmer.
    { name: "Side", values: Object.assign(clockLook("thin", "top", 100, "", 100, 35),
        { lockWidgets: ["weather", "battery", "notifications", "todo"], lockClockOffset: null, lockWidgetsOffset: null,
          lockPlaces: { clock: { x: -0.33, y: 0 }, date: { x: -0.33, y: 0 }, player: { x: -0.33, y: 0 },
                        weather: { x: -0.33, y: 0 }, battery: { x: -0.33, y: 0 }, notifications: { x: -0.33, y: 0 },
                        todo: { x: -0.33, y: 0 } } }) },
    // A bold clock in the middle, the weather and the battery close on either side of it.
    { name: "Flanked", values: Object.assign(clockLook("big", "top", 125, "Inter Display", 100, 30),
        { lockWidgets: ["weather", "battery"], lockClockOffset: null, lockWidgetsOffset: null,
          lockPlaces: { weather: { x: -0.135, y: -0.24 }, battery: { x: 0.135, y: -0.24 } } }) }
];

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

// Desktop widget layouts: a fitting set of widgets, each at its place. Places are laid out in px
// on a 1920 x 1080 screen (widgets 168 px high, small ones 168 wide, medium 352, 16 apart, clear
// of the island and the dock) and kept as fractions, like a dragged widget's.
function widgetLayout(places) {
    const values = {};
    const saved = {};
    for (const kind of DesktopWidgets.kinds) {
        values[kind.key] = kind.name in places;
        if (kind.name in places)
            saved[kind.name] = { x: Math.round(places[kind.name][0] / 1920 * 10000) / 10000,
                                 y: Math.round(places[kind.name][1] / 1080 * 10000) / 10000 };
    }
    values.desktopWidgets = saved;
    return values;
}

const desktopWidgets = [
    { name: "Clean", values: widgetLayout({}) },
    // The corner ones sit 80 px from both edges (below the island's band at the top too).
    // The time and sky, top left.
    { name: "Glance", values: widgetLayout({ clock: [80, 80], weather: [448, 80] }) },
    // A row along the top: the time, a timer and what to do.
    { name: "Focus", values: widgetLayout({ clock: [80, 80], timer: [448, 80], todo: [632, 80] }) },
    // The player at the bottom left, the time above it, the sky beside it.
    { name: "Music", values: widgetLayout({ clock: [80, 608], media: [80, 792], weather: [448, 792] }) },
    // A column on the right, centred top to bottom: the time, the day's events, tasks, and the
    // sky and battery side by side, so its edges are even.
    { name: "Workday", values: widgetLayout({ clock: [1488, 180], calendar: [1488, 364], todo: [1488, 548],
                                             weather: [1488, 732], battery: [1672, 732] }) },
    // All of them in three rows across the top left, keeping to the upper half (pictures often
    // have the ground and their subject lower down).
    { name: "Everything", values: widgetLayout({ clock: [80, 80], calendar: [448, 80], media: [80, 264], todo: [448, 264],
                                                weather: [80, 448], battery: [264, 448], timer: [448, 448] }) },
    // A column on the left, centred top to bottom: the time, the sky and battery, the player
    // (the lock screen's Side look on the desktop).
    { name: "Side", values: widgetLayout({ clock: [80, 272], weather: [80, 456], battery: [264, 456], media: [80, 640] }) }
];

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

// Every setting the lock screen editor changes, for its Cancel.
const lockKeys = ["lockClockStyle", "lockLayout", "lockPlaces", "lockQuietSide", "lockClockOffset", "lockWidgetsOffset", "lockClockSize", "lockClockFont", "lockBlur", "lockDim",
                  "lockWallpaper", "lockClock", "lockDate", "lockWidgets", "lockMedia", "lockLooks"];

// Every setting the desktop editor changes, for its Cancel (the wallpaper is put back apart:
// it isn't a setting). Themes saved, renamed or deleted in it are put back too.
const desktopKeys = ["colorScheme", "colorStyle", "colorContrast", "accentColor",
                     ...DesktopWidgets.keys, "desktopWidgets", "desktopGrid", "desktopGridSize",
                     "glass", "glassOpacity", "blurStyle", "uiScale", "textScale", "cornerScale",
                     "fontSans", "fontMono", "iconTheme", "themes", "widgetLooks"];

// Every setting the dock and island editor changes, for its Cancel.
const dockIslandKeys = ["dockMode", "dockIconSize", "workspaceDots", "hiddenStatusIcons",
                        "clockDate", "clockSeconds", "islandMedia", "dockLooks"];

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
