// Counting waiting updates for services/Updates.qml. Plain JavaScript, so it can be tested on
// its own (tests/tst_updates.qml).
.pragma library

// `checkupdates` and `paru -Qua` both print one line per package, "name old -> new"; the
// service runs them one after the other with a "--- aur" line between. Returns
// { repo: [names], aur: [names] }.
function parse(text) {
    const result = { repo: [], aur: [] };
    let list = result.repo;
    for (const line of text.split("\n")) {
        if (line.trim() === "--- aur") {
            list = result.aur;
            continue;
        }
        const match = line.match(/^(\S+) \S+ -> \S+/);
        if (match)
            list.push(match[1]);
    }
    return result;
}

// "12 updates · 3 from the AUR", "1 update", "" for none.
function summary(repo, aur) {
    const total = repo + aur;
    if (total === 0)
        return "";
    return total + (total === 1 ? " update" : " updates") + (aur > 0 ? " · " + aur + " from the AUR" : "");
}
