// The media menu's accent from the album cover (MediaPanel.qml): the most colorful of the cover's
// main colors, made light enough for a dark menu (dark enough for a light one). Plain JavaScript, so it can be tested on its
// own (tests/tst_mediaaccent.qml).
.pragma library

// `colors`: [{ h, s, l }] (0-1, like Qt's hslHue/hslSaturation/hslLightness); `light`: the menu is
// light (light mode). Returns { h, s, l },
// or null when the cover has no real color (grey, black and white covers keep the theme's accent).
function accent(colors, light) {
    let best = null;
    for (const c of colors) {
        if (c.h < 0 || c.s < 0.2 || c.l < 0.08 || c.l > 0.95)
            continue; // grey, or nearly black or white
        if (!best || c.s > best.s)
            best = c;
    }
    if (!best)
        return null;
    const l = light ? Math.min(Math.max(best.l, 0.28), 0.4) : Math.min(Math.max(best.l, 0.7), 0.82);
    return { h: best.h, s: Math.max(best.s, 0.45), l: l };
}
