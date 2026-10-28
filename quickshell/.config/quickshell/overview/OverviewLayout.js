// Where the overview puts the window previews: a centered grid that keeps each window's shape.
// Plain JavaScript, so it can be tested on its own (tests/tst_overviewlayout.qml).
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
