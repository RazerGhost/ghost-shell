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
        compare(Keybinds.combo(64, "equal"), "Super + +");
    }

    function test_modifierOnly() {
        // Tapping Super: the key is Super itself.
        compare(Keybinds.parts(64, "SUPER_L"), ["Super"]);
    }

    function test_groupsByCategory() {
        const groups = Keybinds.groups([
            bind(64, "W", "Windows: Close window"),
            bind(64, "B", "Apps: Browser"),
            bind(8, "F4", "Windows: Close window"),
            bind(64, "X", "No category")
        ]);
        compare(groups.map(g => g.category), ["Windows", "Apps", "Other"]);
        compare(groups[0].rows, [{ description: "Close window", combos: [["Super", "W"], ["Alt", "F4"]] }]);
        compare(groups[2].rows[0].description, "No category");
    }

    function test_skipsUndescribed() {
        const groups = Keybinds.groups([bind(0, "XF86AudioMute"), bind(64, "L", "Session: Lock")]);
        compare(groups.length, 1);
        compare(groups[0].rows[0].description, "Lock");
    }

    function test_rangeBecomesOne() {
        const binds = [];
        for (let i = 1; i <= 10; i++)
            binds.push(bind(64, String(i % 10), "Workspaces: Go to workspace 1-10"));
        compare(Keybinds.groups(binds)[0].rows[0].combos, [["Super", "1–0"]]);
    }
}
