// Light or dark (Settings -> Appearance; services/ColorScheme.qml). Plain JavaScript, so it can
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
