// Fuzzy search over desktop entries and windows for the launcher, and its other modes (files,
// commands). Plain JavaScript, so it can be tested
// on its own (tests/tst_fuzzy.qml).
.pragma library

// How well `query` matches `text`: -1 if it doesn't, otherwise higher is better.
// Every query character has to appear in `text` in order ("ffx" matches "Firefox").
// Matches at the start of the text or of a word, and consecutive matched characters,
// score extra, so "fi" ranks "Files" above "Profile".
function score(query, text) {
    const q = query.toLowerCase();
    const t = (text || "").toLowerCase();
    if (q.length === 0)
        return 0;

    let total = 0;
    if (t.startsWith(q))
        total += 20;
    else if (t.includes(q))
        total += 10;

    let from = 0;
    let previous = -2;
    for (const ch of q) {
        const found = t.indexOf(ch, from);
        if (found === -1)
            return -1;
        if (found === 0)
            total += 8;
        else if (" -_.".includes(t[found - 1]))
            total += 6;
        if (found === previous + 1)
            total += 4;
        total += 1 - Math.min(found - from, 3); // skipped characters cost a little
        previous = found;
        from = found + 1;
    }
    return total;
}

// The entries matching `query`, best first. Matches on the app's name count double; the
// generic name ("Web Browser") and keywords find apps by what they do. With an empty query,
// every entry in alphabetical order. Entries marked NoDisplay are left out.
function filter(entries, query) {
    const q = query.trim();
    const shown = entries.filter(e => !e.noDisplay);
    if (q === "")
        return shown.sort(byName);
    return scoredApps(shown, q).map(r => r.entry);
}

function byName(a, b) {
    return a.name.localeCompare(b.name);
}

// The matching apps as [{ entry, score }], best first.
function scoredApps(entries, q) {
    const results = [];
    for (const entry of entries) {
        const name = score(q, entry.name);
        const best = Math.max(name < 0 ? -1 : name * 2,
                              score(q, entry.genericName),
                              score(q, Array.from(entry.keywords || []).join(" ")));
        if (best >= 0)
            results.push({ entry: entry, score: best });
    }
    results.sort((a, b) => b.score - a.score || byName(a.entry, b.entry));
    return results;
}

// Apps' own shortcuts (.desktop actions, like Zen's "New Private Window" or Steam's "Library")
// matching `query`, as [{ entry, action }], best first. Stricter than apps: the query has to
// appear as is in the action's name, or in "<app> <action>", so short queries don't flood the
// list. "New Window" actions are left out: opening the app does that.
function actions(entries, query) {
    return scoredActions(entries, query).map(r => ({ entry: r.entry, action: r.action }));
}

function scoredActions(entries, query) {
    const q = query.trim().toLowerCase();
    if (q === "")
        return [];

    const results = [];
    for (const entry of entries) {
        if (entry.noDisplay)
            continue;
        for (const action of Array.from(entry.actions || [])) {
            const name = action.name.toLowerCase();
            if (name === "new window")
                continue;
            const text = name.includes(q) ? name : (entry.name.toLowerCase() + " " + name);
            if (text.includes(q))
                results.push({ entry: entry, action: action, score: score(q, text) });
        }
    }
    results.sort((a, b) => b.score - a.score || a.action.name.localeCompare(b.action.name));
    return results;
}

// Everything the launcher lists for `query`: apps, their shortcuts and open windows as
// [{ entry, action, window }] (action null for an app; entry null for a window), together by how
// well they match. An action's whole name matching ranks it above an app that only matches
// loosely. With an empty query, just the apps. `windows` as for scoredWindows().
function results(entries, query, windows) {
    const q = query.trim();
    const shown = entries.filter(e => !e.noDisplay);
    if (q === "")
        return shown.sort(byName).map(e => ({ entry: e, action: null, window: null }));
    // On equal scores: apps, then their shortcuts, then windows.
    const rank = r => r.window ? 2 : r.action ? 1 : 0;
    return scoredApps(shown, q).map(r => ({ entry: r.entry, action: null, window: null, score: r.score }))
        .concat(scoredActions(shown, q).map(r => ({ entry: r.entry, action: r.action, window: null, score: r.score })))
        .concat(scoredWindows(windows ?? [], q).map(r => ({ entry: null, action: null, window: r.window, score: r.score })))
        .sort((a, b) => b.score - a.score || rank(a) - rank(b))
        .map(r => ({ entry: r.entry, action: r.action, window: r.window }));
}

// What a query asks for: "/ report" searches files, "> htop" runs a command, anything else
// searches apps and windows. { mode: "apps" | "files" | "command", text }.
function mode(query) {
    const trimmed = query.replace(/^\s+/, ""); // no trimStart in QML's engine
    if (trimmed.startsWith("/"))
        return { mode: "files", text: trimmed.slice(1).trim() };
    if (trimmed.startsWith(">"))
        return { mode: "command", text: trimmed.slice(1).trim() };
    return { mode: "apps", text: query };
}

// Open windows matching `query`, as [{ window, score }], best first. `windows` are
// [{ window, title, app }]. Strict like shortcuts (the query has to appear in the title or the
// app's name), so typing an app's name doesn't list every window loosely matching it.
function scoredWindows(windows, query) {
    const q = query.trim().toLowerCase();
    if (q === "")
        return [];
    const results = [];
    for (const w of windows) {
        const best = Math.max(w.title.toLowerCase().includes(q) ? score(q, w.title) : -1,
                              w.app.toLowerCase().includes(q) ? score(q, w.app) : -1);
        if (best >= 0)
            results.push({ window: w.window, score: best });
    }
    return results.sort((a, b) => b.score - a.score);
}

// Lines of `fd --absolute-path` -> [{ path, name, folder }] ("~/" for the home folder), the
// shortest paths first (fewer folders deep is usually what you meant).
function files(text, home) {
    return text.split("\n").filter(l => l !== "")
        .map(path => path.replace(/\/$/, ""))
        .sort((a, b) => a.split("/").length - b.split("/").length || a.localeCompare(b))
        .map(path => {
            const slash = path.lastIndexOf("/");
            const folder = path.slice(0, slash + 1);
            return { path: path, name: path.slice(slash + 1), folder: folder.startsWith(home + "/") ? "~/" + folder.slice(home.length + 1) : folder };
        });
}

// An icon theme name for a file, by its extension; a name without one is likely a folder.
const fileIcons = {
    image: ["png", "jpg", "jpeg", "gif", "webp", "svg", "avif", "heic"],
    video: ["mp4", "mkv", "webm", "mov", "avi"],
    audio: ["mp3", "flac", "ogg", "opus", "wav", "m4a"],
    pdf: ["pdf"],
    archive: ["zip", "tar", "gz", "xz", "zst", "7z", "rar"]
};
const iconNames = {
    image: "image-x-generic", video: "video-x-generic", audio: "audio-x-generic",
    pdf: "application-pdf", archive: "package-x-generic"
};

function fileIcon(name) {
    const dot = name.lastIndexOf(".");
    if (dot <= 0)
        return "folder";
    const ext = name.slice(dot + 1).toLowerCase();
    const kind = Object.keys(fileIcons).find(k => fileIcons[k].includes(ext));
    return kind ? iconNames[kind] : "text-x-generic";
}
