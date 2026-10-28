// Fuzzy search over desktop entries for the launcher. Plain JavaScript, so it can be tested
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

// Everything the launcher lists for `query`: apps and their shortcuts as [{ entry, action }]
// (action null for an app), together by how well they match. An action's whole name matching
// ranks it above an app that only matches loosely. With an empty query, just the apps.
function results(entries, query) {
    const q = query.trim();
    const shown = entries.filter(e => !e.noDisplay);
    if (q === "")
        return shown.sort(byName).map(e => ({ entry: e, action: null }));
    return scoredApps(shown, q).map(r => ({ entry: r.entry, action: null, score: r.score }))
        .concat(scoredActions(shown, q))
        .sort((a, b) => b.score - a.score || (a.action === null ? -1 : 1))
        .map(r => ({ entry: r.entry, action: r.action }));
}
