// The keyboard layouts to choose from in the settings window (InputPage.qml), read from XKB's
// list. Plain JavaScript, so it can be tested on its own (tests/tst_xkblayouts.qml).
.pragma library

// The keyboard layouts in XKB's list (/usr/share/X11/xkb/rules/base.lst), as [{ code, name }]
// sorted by name: the "! layout" section's lines look like "  us              English (US)".
function layouts(baseLst) {
    const result = [];
    let inLayouts = false;
    for (const line of baseLst.split("\n")) {
        if (line.startsWith("!")) {
            inLayouts = line.trim() === "! layout";
            continue;
        }
        const match = inLayouts && line.match(/^\s+(\S+)\s+(.+)$/);
        if (match)
            result.push({ code: match[1], name: match[2].trim() });
    }
    return result.sort((a, b) => a.name.localeCompare(b.name));
}
