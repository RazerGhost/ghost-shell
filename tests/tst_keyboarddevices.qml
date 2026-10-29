import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/KeyboardDevices.js" as Keyboard

TestCase {
    name: "KeyboardDevices"

    function test_activeLayout() {
        compare(Keyboard.activeLayout("at-translated-set-2-keyboard,English (US)"), { keyboard: "at-translated-set-2-keyboard", layout: "English (US)" });
        compare(Keyboard.activeLayout("kb,English (US, intl., with dead keys)").layout, "English (US, intl., with dead keys)");
        compare(Keyboard.activeLayout("nonsense"), null);
    }

    function test_mainKeyboard() {
        const devices = on => JSON.stringify({ keyboards: [
            { name: "power-button", capsLock: false, main: false, active_keymap: "English (US)" },
            { name: "at-translated-set-2-keyboard", capsLock: on, main: true, active_keymap: "Dutch" }
        ] });
        compare(Keyboard.mainKeyboard(devices(true)), { name: "at-translated-set-2-keyboard", layout: "Dutch" });
        compare(Keyboard.mainKeyboard(JSON.stringify({ keyboards: [] })), null);
        compare(Keyboard.mainKeyboard("not json"), null);
    }
}
