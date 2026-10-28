// Turns Hyprland's bind list (`hyprctl binds -j`) into rows for the settings window: one row per
// description, with every key combination that does it.
.pragma library

// Hyprland's modifier bits, in the order they're written.
const modifiers = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]];

const keyNames = {
    Return: "Enter", space: "Space", grave: "`", Delete: "Delete", Print: "Print Screen",
    left: "←", right: "→", up: "↑", down: "↓",
    mouse_down: "Scroll down", mouse_up: "Scroll up",
    "mouse:272": "Left drag", "mouse:273": "Right drag"
};

// "Super + Shift + E" from a modmask and a key name. A bind on a modifier key itself (tapping
// Super) is just the modifier.
function combo(modmask, key) {
    const parts = modifiers.filter(([bit]) => modmask & bit).map(([, name]) => name);
    if (!/^(SUPER|CONTROL|ALT|SHIFT)_[LR]$/.test(key))
        parts.push(keyNames[key] ?? (key.length === 1 ? key.toUpperCase() : key));
    return parts.join(" + ");
}

// [{ description, keys }] in the order the binds were made, for the binds with a description.
// Many combinations for one description (workspaces 1-10) show as the first and last.
function rows(binds) {
    const groups = [];
    for (const bind of binds) {
        if (!bind.has_description)
            continue;
        let group = groups.find(g => g.description === bind.description);
        if (!group) {
            group = { description: bind.description, combos: [] };
            groups.push(group);
        }
        group.combos.push(combo(bind.modmask, bind.key));
    }
    return groups.map(g => ({
        description: g.description,
        keys: g.combos.length > 4 ? g.combos[0] + " … " + g.combos[g.combos.length - 1]
                                  : g.combos.join(" / ")
    }));
}
