import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/Keybinds.js" as Keybinds

TestCase {
    name: "Keybinds"

    function bind(modmask, key, description) {
        return { modmask: modmask, key: key, description: description ?? "", has_description: description !== undefined };
    }

    function test_combo() {
        compare(Keybinds.combo(64, "E"), "Super + E");
        compare(Keybinds.combo(65, "e"), "Super + Shift + E");
        compare(Keybinds.combo(12, "Delete"), "Ctrl + Alt + Delete");
        compare(Keybinds.combo(68, "left"), "Super + Ctrl + ←");
        compare(Keybinds.combo(64, "Return"), "Super + Enter");
        compare(Keybinds.combo(0, "Print"), "Print Screen");
        compare(Keybinds.combo(8, "F4"), "Alt + F4");
        compare(Keybinds.combo(64, "mouse:272"), "Super + Left drag");
    }

    function test_modifierOnly() {
        // Tapping Super: the key is Super itself.
        compare(Keybinds.combo(64, "SUPER_L"), "Super");
    }

    function test_rowsGroupByDescription() {
        const rows = Keybinds.rows([
            bind(64, "W", "Close window"),
            bind(64, "B", "Browser"),
            bind(8, "F4", "Close window")
        ]);
        compare(rows.length, 2);
        compare(rows[0].description, "Close window");
        compare(rows[0].keys, "Super + W / Alt + F4");
        compare(rows[1].keys, "Super + B");
    }

    function test_rowsSkipUndescribed() {
        const rows = Keybinds.rows([bind(0, "XF86AudioMute"), bind(64, "L", "Lock")]);
        compare(rows.length, 1);
        compare(rows[0].description, "Lock");
    }

    function test_rowsLongGroupShowsRange() {
        const binds = [];
        for (let i = 1; i <= 10; i++)
            binds.push(bind(64, String(i % 10), "Go to workspace 1-10"));
        compare(Keybinds.rows(binds)[0].keys, "Super + 1 … Super + 0");
    }
}
