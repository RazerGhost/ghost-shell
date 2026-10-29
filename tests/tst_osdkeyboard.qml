import QtQuick
import QtTest
import "../quickshell/.config/quickshell/osd/Keyboard.js" as Keyboard

TestCase {
    name: "OsdKeyboard"

    function test_layoutName() {
        compare(Keyboard.layoutName("at-translated-set-2-keyboard,English (US)"), "English (US)");
        compare(Keyboard.layoutName("kb,English (US, intl., with dead keys)"), "English (US, intl., with dead keys)");
        compare(Keyboard.layoutName("nonsense"), "");
    }

    function test_capsLock() {
        const devices = on => JSON.stringify({ keyboards: [
            { name: "power-button", capsLock: false, main: false },
            { name: "at-translated-set-2-keyboard", capsLock: on, main: true }
        ] });
        compare(Keyboard.capsLock(devices(true)), true);
        compare(Keyboard.capsLock(devices(false)), false);
        compare(Keyboard.capsLock(JSON.stringify({ keyboards: [] })), null);
        compare(Keyboard.capsLock("not json"), null);
    }
}
