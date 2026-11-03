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
        // A chosen wallpaper turns Hyprland's own picture off; without one it stays.
        verify(HyprlandConfig.lua(defaults, false, true).includes("disable_hyprland_logo = true"));
        verify(!HyprlandConfig.lua(defaults, false, false).includes("disable_hyprland_logo"));
        const off = HyprlandConfig.lua(defaults, false);
        verify(!off.includes("animations"));
        const on = HyprlandConfig.lua(defaults, true);
        verify(on.includes("animations = { enabled = false },"));
        verify(on.includes("shadow = { enabled = false }"));
        // After the settings' own hl.config, so it overrides them.
        verify(on.indexOf("animations") > on.indexOf("wobble"));
    }

    function test_animationSpeed() {
        // Normal (or not set): nothing extra, look.lua's own speeds stand.
        verify(!HyprlandConfig.lua(defaults, false).includes("GhostAnimations"));
        const fast = HyprlandConfig.lua(Object.assign({}, defaults, { animationSpeed: 2 }), false);
        verify(fast.includes('if GhostAnimations then GhostAnimations(2, { windows = "popin 87%", workspaces = "fade" }) end'));
        const off = HyprlandConfig.lua(Object.assign({}, defaults, { animationSpeed: 0 }), false);
        verify(off.includes("hl.config({ animations = { enabled = false } })"));
        // Hand-edited nonsense is normal speed.
        compare(HyprlandConfig.animationSpeed(7), 1);
        compare(HyprlandConfig.animationSpeed("2"), 1);
        compare(HyprlandConfig.animationSpeed(0.5), 0.5);
    }

    function test_animationStyles() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { windowAnimation: "slide", workspaceAnimation: "slidefade" }), false);
        verify(lua.includes('GhostAnimations(1, { windows = "slide", workspaces = "slidefade 20%" })'));
        // Unknown styles are the defaults, which at normal speed need nothing.
        const odd = HyprlandConfig.lua(Object.assign({}, defaults, { windowAnimation: 'x" }) os.exit() --', workspaceAnimation: "spin" }), false);
        verify(!odd.includes("GhostAnimations"));
        verify(!odd.includes("os.exit"));
        // Off stays off whatever the styles.
        verify(HyprlandConfig.lua(Object.assign({}, defaults, { animationSpeed: 0, windowAnimation: "slide" }), false).includes("enabled = false"));
    }

    function test_borderExtras() {
        verify(!HyprlandConfig.lua(defaults, false).includes("borderangle"));
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { borderSpin: true, windowGlow: true, windowKindBorders: true }), false);
        verify(lua.includes('leaf = "borderangle"'));
        verify(lua.includes("glow = { enabled = true"));
        verify(lua.includes("match = { float = true, focus = true }, border_color = GhostColors.tertiary"));
        verify(lua.includes("if GhostColors then"));
    }

    function test_cursor() {
        const lua = HyprlandConfig.lua(Object.assign({}, defaults, { cursorTheme: "Bibata-Modern-Classic", cursorSize: 32 }), false);
        verify(lua.includes('hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")'));
        verify(lua.includes('hl.env("HYPRCURSOR_SIZE", "32")'));
        // Not set, or hand-edited: Adwaita at 24, nothing that breaks the string.
        verify(HyprlandConfig.lua(defaults, false).includes('hl.env("XCURSOR_THEME", "Adwaita")'));
        compare(HyprlandConfig.cursorTheme('a"); os.exit() --'), "Adwaita");
        compare(HyprlandConfig.cursorSize(33), 24);
    }

    function test_greeterData() {
        const data = HyprlandConfig.greeterData({
            keyboardLayout: "us,nl", pointerSpeed: 3, naturalScroll: true, tapToClick: false,
            cursorTheme: "Bibata-Modern-Classic", cursorSize: 32,
            monitors: { "eDP-1": { mode: "1920x1080@165", scale: 1, transform: 0, vrr: 2 },
                        "bad name\"": { mode: "1920x1080@60", scale: 1, transform: 0, vrr: 0 } }
        });
        compare(data, "kb_layout=us,nl\nsensitivity=1\nnatural_scroll=true\ntap_to_click=false\n"
                + "cursor_theme=Bibata-Modern-Classic\ncursor_size=32\nmonitor=eDP-1 1920x1080@165 1 0 2\n");
        // Nothing unsafe gets through: odd values fall back to the defaults.
        compare(HyprlandConfig.greeterData({ keyboardLayout: "us\nrm -rf", cursorTheme: "a\"b" }),
                "kb_layout=us\nsensitivity=0\nnatural_scroll=false\ntap_to_click=true\n"
                + "cursor_theme=Adwaita\ncursor_size=24\n");
    }

    function test_bell() {
        verify(HyprlandConfig.lua({}, false, false, true).includes('bell_sound = "default"'));
        verify(HyprlandConfig.lua({}, false, false, false).includes('bell_sound = "none"'));
        verify(HyprlandConfig.lua({}, false, false).includes('bell_sound = "none"'));
    }
}
