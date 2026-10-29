// Parses `cliphist list` for the clipboard menu. Plain JavaScript, so it can be tested on its
// own (tests/tst_clipboard.qml).
.pragma library

// One line is "<id>\t<preview>". Text previews are the text on one line (cliphist shortens
// long ones with "…"); images look like "[[ binary data 120 KiB png 1920x1080 ]]".
function parse(line) {
    const tab = line.indexOf("\t");
    if (tab < 1)
        throw new Error("unexpected cliphist line: " + line);
    const preview = line.slice(tab + 1);
    const binary = /^\[\[ binary data (\S+ \S+) (\S+)(?: (\d+)x(\d+))? \]\]$/.exec(preview);
    return {
        line: line, // `cliphist delete` wants the whole line back
        id: line.slice(0, tab),
        text: binary ? "" : preview,
        image: binary ? { size: binary[1], format: binary[2], width: Number(binary[3] || 0), height: Number(binary[4] || 0) } : null
    };
}

// All entries from cliphist's output, newest first (cliphist's own order).
function parseAll(output) {
    return output.split("\n").filter(line => line !== "").map(parse);
}

// Entries matching a search: text containing the query (any case). Images only show up
// without a query, or when it's "image".
function filter(entries, query) {
    const q = query.trim().toLowerCase();
    if (q === "")
        return entries;
    return entries.filter(e => e.image ? "image".startsWith(q) : e.text.toLowerCase().includes(q));
}

// The menu's list: pinned texts first (kept apart from cliphist, so they survive "Clear all"),
// then the history. A pin is { pinned: true, text, id: "pin:<n>", line: "", image: null }.
function withPins(pins, entries) {
    const pinned = Array.from(pins ?? []).filter(t => typeof t === "string" && t !== "")
        .map((text, i) => ({ pinned: true, text: text, id: "pin:" + i, line: "", image: null }));
    return pinned.concat(entries);
}

// The pins with `text` added at the end (once), or taken out.
function pin(pins, text) {
    const list = Array.from(pins ?? []);
    return text === "" || list.includes(text) ? list : list.concat([text]);
}

function unpin(pins, text) {
    return Array.from(pins ?? []).filter(t => t !== text);
}
