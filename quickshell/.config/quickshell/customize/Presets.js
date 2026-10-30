// Named looks for the on-screen editors (a gallery of picture cards, like the iOS lock screen
// gallery): picking one sets several settings at once; each can still be changed after. Plain JavaScript, so it can be tested on its own (tests/tst_presets.qml).
.pragma library
.import "../desktop/DesktopWidgets.js" as DesktopWidgets

// The lock and login screens: the clock's style, place, size and font, and the picture's blur
// and darkening.
const lock = [
    { name: "Classic", values: { lockClockStyle: "big", lockLayout: "top", lockClockSize: 100, lockClockFont: "", lockBlur: 100, lockDim: 25, lockClockOffset: null, lockWidgetsOffset: null } },
    { name: "Minimal", values: { lockClockStyle: "thin", lockLayout: "center", lockClockSize: 100, lockClockFont: "", lockBlur: 100, lockDim: 40, lockClockOffset: null, lockWidgetsOffset: null } },
    { name: "Analog", values: { lockClockStyle: "analog", lockLayout: "left", lockClockSize: 100, lockClockFont: "", lockBlur: 60, lockDim: 30, lockClockOffset: null, lockWidgetsOffset: null } },
    { name: "Bold", values: { lockClockStyle: "stacked", lockLayout: "top", lockClockSize: 125, lockClockFont: "Inter Display", lockBlur: 100, lockDim: 25, lockClockOffset: null, lockWidgetsOffset: null } },
    { name: "Editorial", values: { lockClockStyle: "big", lockLayout: "center", lockClockSize: 125, lockClockFont: "C059", lockBlur: 80, lockDim: 35, lockClockOffset: null, lockWidgetsOffset: null } }
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
const lockKeys = ["lockClockStyle", "lockLayout", "lockClockOffset", "lockWidgetsOffset", "lockClockSize", "lockClockFont", "lockBlur", "lockDim",
                  "lockWallpaper", "lockClock", "lockDate", "lockWidgets", "lockMedia"];

// Every setting the desktop editor changes, for its Cancel (the wallpaper is put back apart:
// it isn't a setting). Themes saved, renamed or deleted in it are put back too.
const desktopKeys = ["colorScheme", "colorStyle", "colorContrast", "accentColor",
                     ...DesktopWidgets.keys, "desktopWidgets",
                     "glass", "glassOpacity", "blurStyle", "uiScale", "textScale", "cornerScale",
                     "fontSans", "fontMono", "iconTheme", "themes"];

// Every setting the dock and island editor changes, for its Cancel.
const dockIslandKeys = ["dockMode", "dockIconSize", "workspaceDots", "hiddenStatusIcons",
                        "clockDate", "clockSeconds", "islandMedia"];

// Every setting the windows editor changes, for its Cancel.
const windowsKeys = ["borderSize", "rounding", "borderSpin", "windowGlow", "windowKindBorders",
                     "gapsIn", "gapsOut", "animationSpeed", "windowAnimation", "workspaceAnimation", "wobble"];

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

// The preset whose values all match the settings, else "" (a look of your own). Lists and
// objects (the hidden status icons) by their contents.
function current(values, presets) {
    const same = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
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
