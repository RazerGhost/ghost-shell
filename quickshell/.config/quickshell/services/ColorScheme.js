// How the colors are made (Settings -> Appearance; services/ColorScheme.qml): light or dark,
// matugen's color style and contrast, and an optional fixed accent. Plain JavaScript, so it can
// be tested on its own (tests/tst_colorscheme.qml).
.pragma library
.import "Schedule.js" as Schedule

// Without the weather town's sunrise and sunset, "auto" is light from 07:00 to 19:00.
const fallbackSunrise = 7 * 60;
const fallbackSunset = 19 * 60;

// "dark" or "light" for the setting ("dark", "light" or "auto": dark from sunset to sunrise) at
// `now` (minutes since midnight). An unknown setting is dark, the default.
function mode(setting, now, sunrise, sunset) {
    if (setting === "light")
        return "light";
    if (setting !== "auto")
        return "dark";
    const rise = typeof sunrise === "number" ? sunrise : fallbackSunrise;
    const set = typeof sunset === "number" ? sunset : fallbackSunset;
    return Schedule.active(now, rise, set) ? "light" : "dark";
}

// matugen's scheme types (`matugen image --help`), the settings' color styles.
const styles = ["scheme-tonal-spot", "scheme-vibrant", "scheme-expressive", "scheme-content", "scheme-fidelity",
                "scheme-fruit-salad", "scheme-rainbow", "scheme-neutral", "scheme-monochrome"];

// What wallpaper.sh reads from ~/.local/state/quickshell/scheme, one "key=value" line each.
// Anything unexpected becomes the default, so a hand-edited settings file can't put anything
// else there: mode light or dark, a known style, contrast -1 to 1, accent #rrggbb or "" (the
// wallpaper's own).
function file(mode, style, contrast, accent) {
    const c = typeof contrast === "number" && isFinite(contrast) ? Math.min(1, Math.max(-1, contrast)) : 0;
    return [
        "mode=" + (mode === "light" ? "light" : "dark"),
        "type=" + (styles.includes(style) ? style : styles[0]),
        "contrast=" + c,
        "accent=" + (/^#[0-9a-fA-F]{6}$/.test(accent ?? "") ? accent.toLowerCase() : "")
    ].join("\n") + "\n";
}
