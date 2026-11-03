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

// How windows open and close, and how workspaces switch (Settings -> Appearance -> Windows):
// Hyprland's styles, the first of each the default (look.lua's own).
const windowStyles = { popin: "popin 87%", slide: "slide", gnomed: "gnomed" };
const workspaceStyles = { fade: "fade", slide: "slide", slidevert: "slidevert", slidefade: "slidefade 20%" };

function style(name, styles) {
    return Object.keys(styles).includes(name) ? name : Object.keys(styles)[0];
}

// Hyprland's side: look.lua's GhostAnimations at the factor and styles, or animations off.
function animationLua(value, windows, workspaces) {
    const speed = animationSpeed(value);
    const win = style(windows, windowStyles);
    const ws = style(workspaces, workspaceStyles);
    if (speed === 0)
        return ["-- Animations off (Settings -> Appearance).", "hl.config({ animations = { enabled = false } })", ""];
    if (speed === 1 && win === "popin" && ws === "fade")
        return [];
    return ["-- Animation speed and styles (Settings -> Appearance).",
            `if GhostAnimations then GhostAnimations(${speed}, { windows = "${windowStyles[win]}", workspaces = "${workspaceStyles[ws]}" }) end`, ""];
}

// The window border's extras (Settings -> Appearance -> Windows). Colors come from matugen's
// colors.lua (loaded before this file): the glow's own, and GhostColors for the rules.
function borderLua(v) {
    const lines = [];
    if (v.borderSpin === true)
        // Turns the border's gradient all the time: Hyprland redraws every frame (battery).
        lines.push("-- The border's colors turn.",
                   'hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "linear", style = "loop" })');
    if (v.windowGlow === true)
        lines.push("-- A glow inside the focused window's edge.",
                   "hl.config({ decoration = { glow = { enabled = true, range = 12 } } })");
    if (v.windowKindBorders === true)
        lines.push("-- Floating windows' border in the third color, pinned ones' (picture-in-picture) in the second.",
                   "if GhostColors then",
                   '    hl.window_rule({ name = "ghost-border-floating", match = { float = true, focus = true }, border_color = GhostColors.tertiary })',
                   '    hl.window_rule({ name = "ghost-border-pinned", match = { pin = true }, border_color = GhostColors.secondary })',
                   "end");
    return lines.length ? [...lines, ""] : [];
}

// The pointer (Settings -> Keyboard and mouse): for apps started from now on. The shell also
// runs `hyprctl setcursor` (HyprlandSettings.qml), which changes it at once.
const cursorSizes = [16, 24, 32, 40, 48];

function cursorSize(value) {
    return cursorSizes.includes(value) ? value : 24;
}

// A theme folder's name: letters, digits, space, dot, dash, underscore; else the default.
function cursorTheme(name) {
    return typeof name === "string" && /^[A-Za-z0-9 ._-]+$/.test(name) ? name : "Adwaita";
}

// Seconds without moving before the pointer hides (0: never).
const cursorHideTimes = [0, 3, 5, 10, 30];

function cursorHideAfter(value) {
    return cursorHideTimes.includes(value) ? value : 0;
}

function cursorLua(v) {
    const theme = cursorTheme(v.cursorTheme);
    const size = cursorSize(v.cursorSize);
    return ["-- The pointer (Settings -> Keyboard and mouse): its look, and hiding it while typing",
            "-- or after it's been still a while (like macOS).",
            `hl.env("XCURSOR_THEME", "${theme}")`, `hl.env("XCURSOR_SIZE", "${size}")`,
            `hl.env("HYPRCURSOR_THEME", "${theme}")`, `hl.env("HYPRCURSOR_SIZE", "${size}")`,
            `hl.config({ cursor = { hide_on_key_press = ${v.cursorHideTyping === true}, `
                + `inactive_timeout = ${cursorHideAfter(v.cursorHideAfter)} } })`, ""];
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

// With a wallpaper chosen, Hyprland draws only its background color (the theme's, from
// matugen's colors.lua) until the shell's wallpaper is up, instead of flashing its own picture
// at every login. Without one, its default picture is the wallpaper, so it stays.
const ownWallpaperLua = [
    "hl.config({ misc = { disable_hyprland_logo = true, force_default_wallpaper = 0 } })",
    ""
];

// Apps ringing the bell (a terminal's \a, xdg-system-bell): Hyprland plays the system's bell
// sound itself (0.57), but only while the shell's sounds would play too: Settings -> Sound
// (all sounds, notifications), not during Do Not Disturb or game mode. `bell` is that answer.
function bellLua(bell) {
    return [`hl.config({ misc = { bell_sound = "${bell === true ? "default" : "none"}" } })`, ""];
}

// The Lua file Hyprland loads last (hyprland.lua), from the settings' values, whether game mode
// is on, whether a wallpaper is chosen and whether the bell may ring (bellLua).
function lua(v, gameMode, wallpaperChosen, bell) {
    return [
        "-- Written by Quickshell's Settings (settings/HyprlandSettings.qml); don't edit:",
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
        ...animationLua(v.animationSpeed, v.windowAnimation, v.workspaceAnimation),
        ...borderLua(v),
        ...cursorLua(v),
        ...(gameMode === true ? gameModeLua : []),
        ...(wallpaperChosen === true ? ownWallpaperLua : []),
        ...bellLua(bell),
        // Screens set up in the Display page, by output name (the rest keep monitors.lua's
        // "preferred"); one that isn't safe to write is left out.
        ...Object.entries(v.monitors || {}).map(([output, setup]) => DisplayModes.lua(output, setup)).filter(l => l !== ""),
        "",
        "-- Read by positions.lua.",
        `ShellSettings = { remember_positions = ${v.rememberPositions !== false} }`,
        ""
    ].join("\n");
}

// What the login screen's Hyprland takes from your settings, as data rather than Lua: it runs
// as the greeter user, and Lua from your home folder would run there as that user. key=value
// lines (one monitor= per screen set up in the Display page), checked here and again by the
// root-owned system/etc/greetd/hypr/hyprland.lua, which reads it (through greeter/sync.sh).
function greeterData(v) {
    const speed = Math.max(-1, Math.min(1, number(v.pointerSpeed, 0)));
    const monitors = Object.entries(v.monitors || {})
        .filter(([output, setup]) => DisplayModes.lua(output, setup) !== "")
        .map(([output, setup]) => `monitor=${output} ${setup.mode} ${setup.scale} ${setup.transform} ${setup.vrr}`);
    return [
        `kb_layout=${layoutCode(v.keyboardLayout)}`,
        `sensitivity=${speed}`,
        `natural_scroll=${v.naturalScroll === true}`,
        `tap_to_click=${v.tapToClick !== false}`,
        `cursor_theme=${cursorTheme(v.cursorTheme)}`,
        `cursor_size=${cursorSize(v.cursorSize)}`,
        ...monitors,
        ""
    ].join("\n");
}
