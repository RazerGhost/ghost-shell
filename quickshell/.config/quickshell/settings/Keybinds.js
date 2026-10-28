// Turns Hyprland's bind list (`hyprctl binds -j`) into the settings window's keybinds page, by
// category: binds.lua describes every bind as "Category: what it does". Also used by `ghost
// keybinds` (bin/.local/bin/ghost loads this file in node), so the docs match the page.
.pragma library

// Hyprland's modifier bits, in the order they're written.
const modifiers = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]];

const keyNames = {
    Return: "Enter", space: "Space", grave: "`", equal: "+", minus: "-", period: ".",
    Delete: "Delete", Escape: "Esc", Print: "Print Screen", Tab: "Tab",
    left: "←", right: "→", up: "↑", down: "↓",
    mouse_down: "Scroll down", mouse_up: "Scroll up",
    "mouse:272": "Left drag", "mouse:273": "Right drag"
};

// The keys of one combination, e.g. ["Super", "Shift", "E"]. A bind on a modifier key itself
// (tapping Super) is just the modifier.
function parts(modmask, key) {
    const result = modifiers.filter(([bit]) => modmask & bit).map(([, name]) => name);
    if (!/^(SUPER|CONTROL|ALT|SHIFT)_[LR]$/.test(key))
        result.push(keyNames[key] ?? (key.length === 1 ? key.toUpperCase() : key));
    return result;
}

// "Super + Shift + E".
function combo(modmask, key) {
    return parts(modmask, key).join(" + ");
}

// The combinations for one description: many with the same modifiers (workspaces 1-10) become
// one, with the first and last key ("Super" + "1–0").
function combine(list) {
    const same = list.every(p => p.slice(0, -1).join("+") === list[0].slice(0, -1).join("+"));
    if (list.length > 4 && same)
        return [list[0].slice(0, -1).concat(list[0][list[0].length - 1] + "–" + list[list.length - 1][list[list.length - 1].length - 1])];
    return list;
}

// [{ category, rows: [{ description, combos: [[keys]] }] }], categories and rows in the order
// the binds were made; binds without a description (media keys) are left out. "Close window"
// from "Windows: Close window"; no category: "Other".
function groups(binds) {
    const result = [];
    for (const bind of binds) {
        if (!bind.has_description)
            continue;
        const split = bind.description.match(/^([^:]+):\s*(.+)$/);
        const category = split ? split[1] : "Other";
        const description = split ? split[2] : bind.description;
        let group = result.find(g => g.category === category);
        if (!group) {
            group = { category: category, rows: [] };
            result.push(group);
        }
        let row = group.rows.find(r => r.description === description);
        if (!row) {
            row = { description: description, combos: [] };
            group.rows.push(row);
        }
        const keys = parts(bind.modmask, bind.key);
        if (!row.combos.some(c => c.join("+") === keys.join("+")))
            row.combos.push(keys);
    }
    for (const group of result)
        for (const row of group.rows)
            row.combos = combine(row.combos);
    return result;
}
