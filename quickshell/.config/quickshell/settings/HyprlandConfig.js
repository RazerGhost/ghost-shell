// The Hyprland side of the settings window: the generated ~/.config/hypr/shell-settings.lua.
// Plain JavaScript, so it can be tested on its own (tests/tst_hyprlandconfig.qml).
.pragma library

// A layout code is letters, digits and _ (several separated by commas); anything else is
// replaced by the default, so the generated Lua can't be broken by a hand-edited settings file.
function layoutCode(code) {
    return /^[a-z0-9_]+(,[a-z0-9_]+)*$/.test(code) ? code : "us";
}

function number(value, fallback) {
    return typeof value === "number" && isFinite(value) ? value : fallback;
}

// The Lua file Hyprland loads last (hyprland.lua), from the settings' values.
function lua(v) {
    return [
        "-- Written by Quickshell's settings window (settings/HyprlandSettings.qml); don't edit:",
        "-- it's overwritten. Loaded last by hyprland.lua, so it overrides input.lua and look.lua.",
        "hl.config({",
        "    input = {",
        `        kb_layout   = "${layoutCode(v.keyboardLayout)}",`,
        `        sensitivity = ${number(v.pointerSpeed, 0)},`,
        "        touchpad = {",
        `            natural_scroll = ${v.naturalScroll === true},`,
        `            tap_to_click   = ${v.tapToClick !== false},`,
        "        },",
        "    },",
        "    general = {",
        `        gaps_in     = ${number(v.gapsIn, 5)},`,
        `        gaps_out    = ${number(v.gapsOut, 20)},`,
        `        border_size = ${number(v.borderSize, 2)},`,
        "    },",
        "    decoration = {",
        `        rounding = ${number(v.rounding, 10)},`,
        "    },",
        "})",
        "",
        "-- Read by positions.lua.",
        `ShellSettings = { remember_positions = ${v.rememberPositions !== false} }`,
        ""
    ].join("\n");
}
