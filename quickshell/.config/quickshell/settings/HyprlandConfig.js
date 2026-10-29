// The Hyprland side of the settings window: the generated ~/.config/hypr/shell-settings.lua.
// Plain JavaScript, so it can be tested on its own (tests/tst_hyprlandconfig.qml).
.pragma library
.import "DisplayModes.js" as DisplayModes

// A layout code is letters, digits and _ (several separated by commas); anything else is
// replaced by the default, so the generated Lua can't be broken by a hand-edited settings file.
function layoutCode(code) {
    return /^[a-z0-9_]+(,[a-z0-9_]+)*$/.test(code) ? code : "us";
}

// Hyprland's blur variants that don't animate (the animated ones, like water, cost GPU time
// all the time); anything else falls back to the classic one.
const blurStyles = ["kawase", "frost", "acrylic", "prism", "aurora", "haze"];

function blurStyle(name) {
    return blurStyles.includes(name) ? name : "kawase";
}

function number(value, fallback) {
    return typeof value === "number" && isFinite(value) ? value : fallback;
}

// Settings' animation speeds: 0 is off, 1 normal, 2 twice as fast. Anything else is normal.
// The shell's own animations use the same factor (theme/Theme.qml).
const animationSpeeds = [0, 0.5, 0.75, 1, 1.5, 2];

function animationSpeed(value) {
    return animationSpeeds.includes(value) ? value : 1;
}

// Hyprland's side: look.lua's GhostAnimations at the factor, or animations off.
function animationLua(value) {
    const speed = animationSpeed(value);
    if (speed === 1)
        return [];
    if (speed === 0)
        return ["-- Animations off (Settings -> Appearance).", "hl.config({ animations = { enabled = false } })", ""];
    return ["-- Animation speed (Settings -> Appearance).", `if GhostAnimations then GhostAnimations(${speed}) end`, ""];
}

// Game mode (services/GameMode.qml): what it switches off, after the settings so it wins.
const gameModeLua = [
    "-- Game mode is on (quick settings).",
    "hl.config({",
    "    animations = { enabled = false },",
    "    decoration = { blur = { enabled = false }, shadow = { enabled = false } },",
    "})",
    ""
];

// The Lua file Hyprland loads last (hyprland.lua), from the settings' values and whether game
// mode is on.
function lua(v, gameMode) {
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
        `        blur = { variant = "${blurStyle(v.blurStyle)}" },`,
        `        wobble = { enabled = ${v.wobble === true} },`,
        "    },",
        "})",
        "",
        ...animationLua(v.animationSpeed),
        ...(gameMode === true ? gameModeLua : []),
        // Screens set up in the Display page, by output name (the rest keep monitors.lua's
        // "preferred"); one that isn't safe to write is left out.
        ...Object.entries(v.monitors || {}).map(([output, setup]) => DisplayModes.lua(output, setup)).filter(l => l !== ""),
        "",
        "-- Read by positions.lua.",
        `ShellSettings = { remember_positions = ${v.rememberPositions !== false} }`,
        ""
    ].join("\n");
}
