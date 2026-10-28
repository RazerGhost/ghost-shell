// Reading Unicode's emoji list (emoji-test.txt from the unicode-emoji package) and searching
// it, for the emoji picker. Plain JavaScript, so it can be tested on its own
// (tests/tst_emoji.qml).
.pragma library

// The emoji, in Unicode's order, as [{ emoji, name, group }]. Lines look like
//   1F600 ; fully-qualified # 😀 E1.0 grinning face
// under "# group: Smileys & Emotion" headers. Only fully-qualified ones; skin-tone variants and
// the "Component" group (bare skin tones, hair styles) are left out, to keep the grid short.
function parse(text) {
    const emoji = [];
    let group = "";
    for (const line of text.split("\n")) {
        if (line.startsWith("# group: ")) {
            group = line.slice(9).trim();
            continue;
        }
        if (line.startsWith("#") || group === "Component")
            continue;
        const match = line.match(/;\s*fully-qualified\s*#\s*(\S+)\s+E\d+\.\d+\s+(.+)$/);
        if (!match || match[2].includes("skin tone"))
            continue;
        emoji.push({ emoji: match[1], name: match[2].trim(), group: group });
    }
    return emoji;
}

// The emoji whose name has every word of `query` in it, best first: the name starting with
// the query, then a word of it starting with each query word, then anywhere. Unicode's order
// stays within each of those.
function filter(emoji, query) {
    const q = query.trim().toLowerCase();
    if (q === "")
        return emoji;
    const words = q.split(/\s+/);
    const rank = e => {
        const name = e.name.toLowerCase();
        if (!words.every(w => name.includes(w)))
            return -1;
        if (name.startsWith(q))
            return 0;
        const nameWords = name.split(/[\s:-]+/);
        return words.every(w => nameWords.some(n => n.startsWith(w))) ? 1 : 2;
    };
    return emoji.map(e => ({ e: e, rank: rank(e) }))
        .filter(r => r.rank >= 0)
        .sort((a, b) => a.rank - b.rank)
        .map(r => r.e);
}
