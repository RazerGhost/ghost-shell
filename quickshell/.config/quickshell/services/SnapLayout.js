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

function layout(name) {
    const l = layouts[name];
    if (!l)
        throw new Error("unknown snap layout: " + name);
    return l;
}
