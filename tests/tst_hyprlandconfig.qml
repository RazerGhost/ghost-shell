import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/HyprlandConfig.js" as HyprlandConfig

TestCase {
    name: "HyprlandConfig"

    readonly property var defaults: ({
        keyboardLayout: "us", pointerSpeed: 0, naturalScroll: false, tapToClick: true,
        gapsIn: 5, gapsOut: 20, borderSize: 2, rounding: 10, rememberPositions: true
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

    function test_badNumbersFallBack() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { gapsIn: "lots", rounding: NaN }));
        verify(lua.includes("gaps_in     = 5,"));
        verify(lua.includes("rounding = 10,"));
    }

    function test_layouts() {
        const lst = [
            "! model",
            "  pc105           Generic 105-key PC",
            "",
            "! layout",
            "  us              English (US)",
            "  nl              Dutch",
            "  de              German",
            "",
            "! variant",
            "  intl            us: English (US, intl., with dead keys)"
        ].join("\n");
        compare(HyprlandConfig.layouts(lst), [
            { code: "nl", name: "Dutch" },
            { code: "us", name: "English (US)" },
            { code: "de", name: "German" }
        ]);
    }
}
