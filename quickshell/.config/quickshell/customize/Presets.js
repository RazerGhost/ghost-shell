// Named looks for the on-screen editors (a gallery of picture cards, like the iOS lock screen
// gallery): picking one sets several settings at once; each can still be changed after. Plain JavaScript, so it can be tested on its own (tests/tst_presets.qml).
.pragma library
.import "../desktop/DesktopWidgets.js" as DesktopWidgets

// The lock and login screens: the clock's style, place, size and font, and the picture's blur
// and darkening.
const lock = [
    { name: "Classic", values: { lockClockStyle: "big", lockLayout: "top", lockClockSize: 100, lockClockFont: "", lockBlur: 100, lockDim: 25 } },
    { name: "Minimal", values: { lockClockStyle: "thin", lockLayout: "center", lockClockSize: 100, lockClockFont: "", lockBlur: 100, lockDim: 40 } },
    { name: "Analog", values: { lockClockStyle: "analog", lockLayout: "left", lockClockSize: 100, lockClockFont: "", lockBlur: 60, lockDim: 30 } },
    { name: "Bold", values: { lockClockStyle: "stacked", lockLayout: "top", lockClockSize: 125, lockClockFont: "Inter Display", lockBlur: 100, lockDim: 25 } },
    { name: "Editorial", values: { lockClockStyle: "big", lockLayout: "center", lockClockSize: 125, lockClockFont: "C059", lockBlur: 80, lockDim: 35 } }
];

// Every setting the lock screen editor changes, for its Cancel.
const lockKeys = ["lockClockStyle", "lockLayout", "lockClockSize", "lockClockFont", "lockBlur", "lockDim",
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

// The preset whose values all match the settings, else "" (a look of your own).
function current(values, presets) {
    const match = presets.find(p => Object.keys(p.values).every(k => values?.[k] === p.values[k]));
    return match ? match.name : "";
}

// Sets a preset's values on `values` (Settings.values); unknown names change nothing.
function apply(values, presets, name) {
    const preset = presets.find(p => p.name === name);
    if (!preset)
        return;
    for (const key of Object.keys(preset.values))
        values[key] = preset.values[key];
}
