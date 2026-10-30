// Your saved looks for the whole desktop, like Android's themes (Settings' themes, the desktop
// editor's Themes tab): the wallpaper and every visual setting that goes with it, switched in
// one click. Not the shell's and text's sizes: those are how you read, not a look. Plain
// JavaScript, so it can be tested on its own (tests/tst_themes.qml).
.pragma library
.import "../desktop/DesktopWidgets.js" as DesktopWidgets
.import "Presets.js" as Presets
.import "SavedLooks.js" as SavedLooks

const keys = ["colorScheme", "colorStyle", "colorContrast", "accentColor",
              "glass", "glassOpacity", "blurStyle", "cornerScale", "fontSans", "fontMono", "iconTheme",
              ...DesktopWidgets.keys, "desktopWidgets"];

// The saved list made safe (a hand-edited file can't break the tab): each with a name, a
// wallpaper path ("" for none), its accent color for the card, and only known keys.
function valid(saved) {
    if (!Array.isArray(saved))
        return [];
    return saved.filter(t => typeof t?.name === "string" && t.name !== "" && typeof t.wallpaper === "string"
                             && typeof t.values === "object" && t.values !== null)
        .map(t => {
            const values = {};
            for (const key of keys)
                if (key in t.values)
                    values[key] = t.values[key];
            return { name: t.name, wallpaper: t.wallpaper, primary: typeof t.primary === "string" ? t.primary : "", values };
        })
        // Without any of its settings left it would match every look on its wallpaper.
        .filter(t => Object.keys(t.values).length > 0);
}

// A theme's values that fit the settings they go into: each of the same kind as the setting is
// now (a number for a number, an object for the widgets' places), so a hand-edited file can't
// put text where a number goes.
function applicable(values, current) {
    const kind = v => v === null ? "null" : Array.isArray(v) ? "array" : typeof v;
    const out = {};
    for (const key of Object.keys(values))
        if (kind(values[key]) === kind(current[key]))
            out[key] = values[key];
    return out;
}

// The look now as a theme named "Theme N" (the first number not taken).
function made(themes, values, wallpaper, primary) {
    let n = 1;
    while (themes.some(t => t.name === "Theme " + n))
        n++;
    const saved = {};
    for (const key of keys)
        saved[key] = JSON.parse(JSON.stringify(values[key] ?? null));
    return { name: "Theme " + n, wallpaper, primary, values: saved };
}

// The theme the desktop looks like now, else "" (changed since, or never saved).
function current(themes, values, wallpaper) {
    const match = themes.find(t => t.wallpaper === wallpaper
                                   && Object.keys(t.values).every(k => Presets.same(values[k], t.values[k])));
    return match ? match.name : "";
}

// `themes` with the one named `from` called `to` (trimmed); the same list when the new name is
// empty or another theme has it (SavedLooks', like the editors' own looks).
function renamed(themes, from, to) {
    return SavedLooks.renamed(themes, from, to, []);
}

function removed(themes, name) {
    return SavedLooks.removed(themes, name);
}
