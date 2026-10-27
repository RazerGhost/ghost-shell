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
    const byName = (a, b) => a.name.localeCompare(b.name);
    if (q === "")
        return shown.sort(byName);

    const results = [];
    for (const entry of shown) {
        const name = score(q, entry.name);
        const best = Math.max(name < 0 ? -1 : name * 2,
                              score(q, entry.genericName),
                              score(q, Array.from(entry.keywords || []).join(" ")));
        if (best >= 0)
            results.push({ entry: entry, score: best });
    }
    results.sort((a, b) => b.score - a.score || byName(a.entry, b.entry));
    return results.map(r => r.entry);
}
