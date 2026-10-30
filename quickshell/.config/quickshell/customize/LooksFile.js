// Your themes and looks across machines: `ghost looks export` writes them into the repo as
// looks.json, `ghost looks import` (or the desktop editor's Themes tab) merges that into this
// machine's settings. Your home folder is written as "~", so a picture in it is found on another
// machine with another home path. Plain JavaScript with no imports: the QML tests
// (tests/tst_looksfile.qml) and bun (modules/core/looks.sh) both load it.
.pragma library

// The settings that hold them: the desktop's themes and each editor's own looks.
const keys = ["themes", "lockLooks", "dockLooks", "windowLooks", "widgetLooks"];

// A path in the home folder written with "~" (`home` -> "~"), or back (`toHome`).
function path(value, home, toHome) {
    if (typeof value !== "string")
        return value;
    if (toHome)
        return value === "~" || value.startsWith("~/") ? home + value.slice(1) : value;
    return value === home || value.startsWith(home + "/") ? "~" + value.slice(home.length) : value;
}

// One look with its picture paths moved: a theme's wallpaper, a lock look's picture.
function moved(look, home, toHome) {
    const out = JSON.parse(JSON.stringify(look));
    if ("wallpaper" in out)
        out.wallpaper = path(out.wallpaper, home, toHome);
    if (out.values && "lockWallpaper" in out.values)
        out.values.lockWallpaper = path(out.values.lockWallpaper, home, toHome);
    return out;
}

const list = value => Array.isArray(value) ? value : [];

// The file's contents from the settings: each list, its paths with "~".
function exported(settings, home) {
    const out = { version: 1 };
    for (const key of keys)
        out[key] = list(settings?.[key]).map(look => moved(look, home, false));
    return out;
}

// The settings with the file's looks merged in: one with the same name as one here replaces it
// (the file is what was shared), new ones are added after; the others here stay. Returns only
// the lists (the keys above), to write over the settings'.
function imported(settings, file, home) {
    const out = {};
    for (const key of keys) {
        const mine = list(settings?.[key]);
        const theirs = list(file?.[key]).filter(look => typeof look?.name === "string" && look.name !== "")
            .map(look => moved(look, home, true));
        const merged = mine.map(look => theirs.find(t => t.name === look.name) ?? look);
        for (const look of theirs)
            if (!mine.some(m => m.name === look.name))
                merged.push(look);
        out[key] = merged;
    }
    return out;
}
