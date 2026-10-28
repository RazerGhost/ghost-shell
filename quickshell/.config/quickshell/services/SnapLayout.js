// Where a snapped window goes, for services/Snap.qml. Plain JavaScript, so it can be tested on
// its own (tests/tst_snaplayout.qml).
.pragma library

// Each layout is a cell in a grid over the screen: `cols` x `rows` cells, starting at `col`,
// `row` and spanning `span` columns (one row unless `rowSpan`).
const layouts = {
    "left":             { cols: 2, rows: 1, col: 0, row: 0 },
    "right":            { cols: 2, rows: 1, col: 1, row: 0 },
    "top-left":         { cols: 2, rows: 2, col: 0, row: 0 },
    "top-right":        { cols: 2, rows: 2, col: 1, row: 0 },
    "bottom-left":      { cols: 2, rows: 2, col: 0, row: 1 },
    "bottom-right":     { cols: 2, rows: 2, col: 1, row: 1 },
    "left-third":       { cols: 3, rows: 1, col: 0, row: 0 },
    "center-third":     { cols: 3, rows: 1, col: 1, row: 0 },
    "right-third":      { cols: 3, rows: 1, col: 2, row: 0 },
    "left-two-thirds":  { cols: 3, rows: 1, col: 0, row: 0, span: 2 },
    "right-two-thirds": { cols: 3, rows: 1, col: 1, row: 0, span: 2 },
};

// The layout that fills the rest of the screen next to `name`, for Snap Assist; "" when there's
// no single one (quarters, the center third).
const complements = {
    "left": "right",
    "right": "left",
    "left-third": "right-two-thirds",
    "right-third": "left-two-thirds",
    "left-two-thirds": "right-third",
    "right-two-thirds": "left-third",
};

function complement(name) {
    layout(name); // throws for unknown names
    return complements[name] || "";
}

function names() {
    return Object.keys(layouts);
}

function layout(name) {
    const l = layouts[name];
    if (!l)
        throw new Error("unknown snap layout: " + name);
    return l;
}

// Hyprland's gap options read like CSS: "20", "20 10", or "top right bottom left".
function parseGaps(css) {
    const v = css.trim().split(/\s+/).map(Number);
    if (v.length === 0 || v.some(isNaN))
        throw new Error("unexpected gaps: " + css);
    const [top, right = top, bottom = top, left = right] = v;
    return { top: top, right: right, bottom: bottom, left: left };
}

// The window's rectangle for `name`. `area` is the usable part of the monitor (minus what the
// island and other bars reserve), in logical pixels; `gapsOut` the space to the screen edges;
// `gapsIn` Hyprland's gaps_in (each window keeps it on every side, so two windows sit
// 2 * gapsIn apart).
function rect(name, area, gapsOut, gapsIn) {
    const l = layout(name);
    const gap = gapsIn * 2;
    const x0 = area.x + gapsOut.left;
    const y0 = area.y + gapsOut.top;
    const width = area.width - gapsOut.left - gapsOut.right;
    const height = area.height - gapsOut.top - gapsOut.bottom;
    const cellW = (width - gap * (l.cols - 1)) / l.cols;
    const cellH = (height - gap * (l.rows - 1)) / l.rows;
    const span = l.span || 1;
    const rowSpan = l.rowSpan || 1;
    return {
        x: Math.round(x0 + l.col * (cellW + gap)),
        y: Math.round(y0 + l.row * (cellH + gap)),
        width: Math.round(cellW * span + gap * (span - 1)),
        height: Math.round(cellH * rowSpan + gap * (rowSpan - 1))
    };
}

// The layout a window exactly fills (geometry: { at: [x, y], size: [w, h] }), or "" when it isn't
// snapped (moved or resized by hand since). Snap.qml remembers a window's spot only then.
function snappedLayout(geometry, area, gapsOut, gapsIn) {
    for (const name of names()) {
        const r = rect(name, area, gapsOut, gapsIn);
        if (r.x === geometry.at[0] && r.y === geometry.at[1]
                && r.width === geometry.size[0] && r.height === geometry.size[1])
            return name;
    }
    return "";
}

// Where a window goes when it won't shrink to its layout's rectangle `r` (an app's minimum size,
// like Discord's 972 px against a 920 px half): it stays against the layout's outer side, and the
// extra size overlaps towards the middle, like Windows. Returns { x, y }.
function fit(name, r, width, height) {
    const l = layout(name);
    const span = l.span || 1;
    const extraW = Math.max(0, width - r.width);
    const extraH = Math.max(0, height - r.height);
    const align = (start, count, size, extra) =>
        start === 0 ? 0                          // touches the left/top edge: grow right/down
        : start + size === count ? -extra        // touches the right/bottom edge: grow left/up
        : -Math.round(extra / 2);                // in the middle: grow both ways
    return {
        x: r.x + align(l.col, l.cols, span, extraW),
        y: r.y + align(l.row, l.rows, l.rowSpan || 1, extraH)
    };
}
