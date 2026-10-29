// Settings -> Appearance -> Size: how much bigger or smaller the shell, its text and its corners
// are, for theme/Theme.qml. Plain JavaScript, so it can be tested on its own
// (tests/tst_themescale.qml).
.pragma library

const sizes = [0.85, 0.9, 1, 1.1, 1.25];       // the shell: spacing, icons, panels
const textSizes = [0.9, 1, 1.1, 1.2, 1.3];     // on top of that, the text
const corners = [0, 0.5, 1, 1.5];              // 0 is square, 1 the normal roundness

// One of `allowed`, else 1: a hand-edited settings file can't make the shell unusable.
function pick(value, allowed) {
    return allowed.includes(value) ? value : 1;
}

// A size in px at `scale`, whole pixels, never below 1 (a 1 px line stays a line).
function px(base, scale) {
    return Math.max(1, Math.round(base * scale));
}

// A corner radius: "full" (a pill) stays a pill unless corners are square.
function radius(base, scale, corner) {
    return base >= 999 ? (corner === 0 ? 0 : 999) : Math.round(base * scale * corner);
}
