// Your own looks in an editor's Looks gallery (customize/LooksTile.qml), beside its presets:
// [{ name, values }] in a setting per gallery (lockLooks, dockLooks, windowLooks, widgetLooks).
// Desktop themes (Themes.js) are the same idea with a wallpaper. Plain JavaScript, so it can be
// tested on its own (tests/tst_savedlooks.qml).
.pragma library
.import "Presets.js" as Presets

// The saved list made safe (a hand-edited file can't break the gallery): named, with only
// `keys`, and at least one of them.
function valid(saved, keys) {
    const list = Presets.plain(saved);
    if (!Array.isArray(list))
        return [];
    return list
        .filter(l => typeof l?.name === "string" && l.name !== "" && typeof l.values === "object" && l.values !== null)
        .map(l => {
            const values = {};
            for (const key of keys)
                if (key in l.values)
                    values[key] = l.values[key];
            return { name: l.name, values };
        })
        .filter(l => Object.keys(l.values).length > 0);
}

// The settings now as a look named "<prefix> N" (the first number not taken among `taken`
// names): copies, so changing a setting later doesn't change the look.
function made(taken, values, keys, prefix) {
    let n = 1;
    while (taken.includes(prefix + " " + n))
        n++;
    const saved = {};
    for (const key of keys) {
        // A list read back from settings.json is array-like: kept as a real list.
        saved[key] = JSON.parse(JSON.stringify(Presets.plain(values[key]) ?? null));
    }
    return { name: prefix + " " + n, values: saved };
}

// `looks` with the one named `from` called `to` (trimmed); the same list when the new name is
// empty or taken (also by a preset: pass their names in `taken`).
function renamed(looks, from, to, taken) {
    const name = String(to).trim();
    if (name === "" || (taken ?? []).includes(name) || looks.some(l => l.name === name && l.name !== from))
        return looks.slice();
    return looks.map(l => l.name === from ? Object.assign({}, l, { name }) : l);
}

function removed(looks, name) {
    return looks.filter(l => l.name !== name);
}
