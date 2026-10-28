import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/DisplayModes.js" as DisplayModes

TestCase {
    name: "DisplayModes"

    function test_modes() {
        compare(DisplayModes.modes(["1280x720@165.00Hz", "1920x1080@60.00Hz", "1920x1080@165.00Hz", "1920x1080@164.99Hz", "junk"]), [
            { mode: "1920x1080@165", label: "1920 × 1080, 165 Hz" },
            { mode: "1920x1080@60", label: "1920 × 1080, 60 Hz" },
            { mode: "1280x720@165", label: "1280 × 720, 165 Hz" }
        ]);
    }

    function test_current() {
        const laptop = { width: 1920, height: 1080, refreshRate: 165.002, scale: 1, transform: 0 };
        compare(DisplayModes.current(laptop, undefined), { mode: "1920x1080@165", scale: 1, transform: 0, vrr: 2 });
        compare(DisplayModes.current(laptop, 0).vrr, 0);
    }

    function test_lua() {
        compare(DisplayModes.lua("eDP-1", { mode: "1920x1080@165", scale: 1.25, transform: 0, vrr: 2 }),
                'hl.monitor({ output = "eDP-1", mode = "1920x1080@165", position = "auto", scale = 1.25, transform = 0, vrr = 2 })');
        // Anything odd (a hand-edited settings file) gives nothing rather than broken Lua.
        compare(DisplayModes.lua('eDP-1" })', { mode: "1920x1080@165", scale: 1, transform: 0, vrr: 2 }), "");
        compare(DisplayModes.lua("eDP-1", { mode: "huge", scale: 1, transform: 0, vrr: 2 }), "");
        compare(DisplayModes.lua("eDP-1", { mode: "1920x1080@165", scale: 9, transform: 0, vrr: 2 }), "");
    }
}
