// The window menu's snap spots as pictures (snap/SnapLayouts.qml draws each as a little screen
// with its cell lit). Hyprland's layout does the real placing: hypr/.config/hypr/tiling.lua has
// the same spot names. Plain JavaScript, so it can be tested on its own (tests/tst_snaplayout.qml).
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

// Super+Up / Super+Down on a snapped window, like Windows 11: a half goes to its top or bottom
// quarter, a quarter back to its half. null: not from this spot (Up maximizes, Down minimizes).
function nextSpot(spot, direction) {
    const steps = {
        up:   { left: "top-left", right: "top-right", "bottom-left": "left", "bottom-right": "right" },
        down: { left: "bottom-left", right: "bottom-right", "top-left": "left", "top-right": "right" }
    };
    return steps[direction]?.[spot] ?? null;
}

// Whether a window at `box` ({ x, y, w, h }) is still in `spot` of `area` (the screen): its middle
// inside the spot's cell. A window swapped, dragged elsewhere or floated since it was snapped isn't,
// and Super+Up / Down then treat it as not snapped.
function holds(spot, box, area) {
    const l = layouts[spot];
    if (!l || !box || !area || area.w <= 0 || area.h <= 0)
        return false;
    const cx = box.x + box.w / 2, cy = box.y + box.h / 2;
    const left = area.x + area.w * l.col / l.cols;
    const right = area.x + area.w * (l.col + (l.span ?? 1)) / l.cols;
    const top = area.y + area.h * l.row / l.rows;
    const bottom = area.y + area.h * (l.row + 1) / l.rows;
    return cx >= left && cx < right && cy >= top && cy < bottom;
}

function layout(name) {
    const l = layouts[name];
    if (!l)
        throw new Error("unknown snap layout: " + name);
    return l;
}
