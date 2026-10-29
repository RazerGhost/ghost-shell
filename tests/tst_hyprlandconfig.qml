import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/HyprlandConfig.js" as HyprlandConfig

TestCase {
    name: "HyprlandConfig"

    readonly property var defaults: ({
        keyboardLayout: "us", pointerSpeed: 0, naturalScroll: false, tapToClick: true,
        gapsIn: 5, gapsOut: 20, borderSize: 2, rounding: 10, rememberPositions: true,
        blurStyle: "kawase", wobble: false
    })

    function test_luaHasTheValues() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { keyboardLayout: "nl", gapsOut: 12, naturalScroll: true }));
        verify(lua.includes('kb_layout   = "nl",'));
        verify(lua.includes("gaps_out    = 12,"));
        verify(lua.includes("natural_scroll = true,"));
        verify(lua.includes("tap_to_click   = true,"));
        verify(lua.includes("ShellSettings = { remember_positions = true }"));
    }

    function test_badLayoutFallsBack() {
        // A hand-edited settings file must not be able to break out of the Lua string.
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { keyboardLayout: 'us" } os.execute("x") --' }));
        verify(lua.includes('kb_layout   = "us",'));
        verify(!lua.includes("os.execute"));
        compare(HyprlandConfig.layoutCode("us,nl"), "us,nl");
        compare(HyprlandConfig.layoutCode("US"), "us");
    }

    function test_blurAndWobble() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { blurStyle: "frost", wobble: true }));
        verify(lua.includes('blur = { variant = "frost" },'));
        verify(lua.includes("wobble = { enabled = true },"));
        // A hand-edited style can't break the Lua or pick an animated variant.
        verify(HyprlandConfig.lua(Object.assign({}, defaults, { blurStyle: 'x" }' })).includes('variant = "kawase"'));
        verify(HyprlandConfig.lua(Object.assign({}, defaults, { blurStyle: "water" })).includes('variant = "kawase"'));
    }

    function test_monitors() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { monitors: {
            "eDP-1": { mode: "1920x1080@60", scale: 1, transform: 0, vrr: 0 },
            'bad" })': { mode: "1920x1080@60", scale: 1, transform: 0, vrr: 0 }
        } }));
        verify(lua.includes('hl.monitor({ output = "eDP-1", mode = "1920x1080@60"'));
        verify(!lua.includes("bad"));
    }

    function test_badNumbersFallBack() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { gapsIn: "lots", rounding: NaN }));
        verify(lua.includes("gaps_in     = 5,"));
        verify(lua.includes("rounding = 10,"));
    }

    function test_gameMode() {
        const off = HyprlandConfig.lua(defaults, false);
        verify(!off.includes("animations"));
        const on = HyprlandConfig.lua(defaults, true);
        verify(on.includes("animations = { enabled = false },"));
        verify(on.includes("shadow = { enabled = false }"));
        // After the settings' own hl.config, so it overrides them.
        verify(on.indexOf("animations") > on.indexOf("wobble"));
    }
}
