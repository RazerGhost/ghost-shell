// A grid of window previews that keeps each window's shape: the overview and Snap Assist. Plain
// JavaScript, so it can be tested on its own (tests/tst_windowgrid.qml).
.pragma library

// `windows` is [{ width, height }] (real sizes). Every column count is tried; the one where the
// previews cover the most area wins. A preview is never larger than its window, and `label` px
// are kept under each one for its title. Returns rows: [[{ index, width, height }]].
function grid(windows, areaWidth, areaHeight, gap, label) {
    const n = windows.length;
    let best = [];
    let bestArea = -1;
    for (let cols = 1; cols <= n; cols++) {
        const rowCount = Math.ceil(n / cols);
        const cellWidth = (areaWidth - gap * (cols - 1)) / cols;
        const cellHeight = (areaHeight - gap * (rowCount - 1)) / rowCount - label;
        if (cellWidth <= 0 || cellHeight <= 0)
            continue;

        const rows = [];
        let area = 0;
        windows.forEach((w, index) => {
            const aspect = w.width / w.height;
            const width = Math.min(cellWidth, cellHeight * aspect, w.width);
            const height = width / aspect;
            area += width * height;
            if (index % cols === 0)
                rows.push([]);
            rows[rows.length - 1].push({ index: index, width: Math.floor(width), height: Math.floor(height) });
        });
        if (area > bestArea) {
            bestArea = area;
            best = rows;
        }
    }
    return best;
}

// The window next to `index` in `rows` (from grid()) for an arrow key: "left"/"right" step
// through the windows in order (wrapping around), "up"/"down" go to the row above or below, to
// the window at about the same place (the last one if that row is shorter). Stays put at the
// top and bottom.
function neighbour(rows, index, direction) {
    const flat = [].concat(...rows); // (no Array.flat in Qt's JavaScript)
    const count = flat.length;
    if (count === 0)
        return -1;
    if (direction === "left")
        return (index - 1 + count) % count;
    if (direction === "right")
        return (index + 1) % count;
    const row = rows.findIndex(r => r.some(cell => cell.index === index));
    const column = rows[row].findIndex(cell => cell.index === index);
    const target = rows[row + (direction === "down" ? 1 : -1)];
    if (!target)
        return index;
    return target[Math.min(column, target.length - 1)].index;
}
