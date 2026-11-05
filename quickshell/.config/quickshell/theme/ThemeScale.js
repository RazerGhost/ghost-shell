// Settings -> Appearance -> Size: how much bigger or smaller the shell, its text and its corners
// are, for theme/Theme.qml. Plain JavaScript, so it can be tested on its own
// (tests/tst_themescale.qml).
.pragma library

// Down to 75 % and 80 %: the same 1920 x 1080 is about 1.5 times bigger on a 24" monitor than on
// the laptop's 16" screen (2026-11-05), and the size is per machine (settings.json).
const sizes = [0.75, 0.8, 0.85, 0.9, 1, 1.1, 1.25];  // the shell: spacing, icons, panels
const textSizes = [0.8, 0.9, 1, 1.1, 1.2, 1.3];      // on top of that, the text
const corners = [0, 0.5, 1, 1.5];              // 0 is square, 1 the normal roundness
const dockIcons = [36, 44, 52, 60];            // the dock's app icons, px at 100 %
const launcherWidths = [480, 560, 640, 720];   // px at 100 %
const launcherRows = [5, 6, 8, 10, 12];        // results shown before the list scrolls
const workspaceDots = [0, 3, 4, 5, 6, 8, 10];  // always shown; 0 = only the ones in use

// One of `allowed`, else `fallback` (1 when not given): a hand-edited settings file can't make
// the shell unusable.
function pick(value, allowed, fallback) {
    return allowed.includes(value) ? value : (fallback ?? 1);
}

// A size in px at `scale`, whole pixels, never below 1 (a 1 px line stays a line).
function px(base, scale) {
    return Math.max(1, Math.round(base * scale));
}

// A corner radius: "full" (a pill) stays a pill unless corners are square.
function radius(base, scale, corner) {
    return base >= 999 ? (corner === 0 ? 0 : 999) : Math.round(base * scale * corner);
}
