import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/WindowGrid.js" as WindowGrid

TestCase {
    name: "WindowGrid"

    function test_empty() {
        compare(WindowGrid.grid([], 1000, 800, 20, 30), []);
    }

    function test_singleWindowKeepsShapeAndFits() {
        const rows = WindowGrid.grid([{ width: 1600, height: 900 }], 1000, 800, 20, 30);
        compare(rows.length, 1);
        const w = rows[0][0];
        compare(w.width, 1000);       // as wide as the area
        compare(w.height, 562);       // 16:9 kept (1000 / 1.777, floored)
    }

    function test_neverLargerThanTheWindow() {
        const rows = WindowGrid.grid([{ width: 400, height: 300 }], 1800, 900, 20, 30);
        compare(rows[0][0].width, 400);
        compare(rows[0][0].height, 300);
    }

    function test_fourWindowsMakeTwoRows() {
        const windows = [];
        for (let i = 0; i < 4; i++)
            windows.push({ width: 1600, height: 900 });
        const rows = WindowGrid.grid(windows, 1800, 900, 20, 30);
        compare(rows.length, 2);
        compare(rows[0].length, 2);
        compare(rows[1][1].index, 3);
    }

    function test_wideAreaPutsTwoSideBySide() {
        const rows = WindowGrid.grid([{ width: 800, height: 800 }, { width: 800, height: 800 }], 1800, 600, 20, 30);
        compare(rows.length, 1);
        compare(rows[0].length, 2);
    }

    function test_neighbour() {
        // Two rows: [0, 1, 2] and [3, 4].
        const rows = [[{ index: 0 }, { index: 1 }, { index: 2 }], [{ index: 3 }, { index: 4 }]];
        compare(WindowGrid.neighbour(rows, 0, "right"), 1);
        compare(WindowGrid.neighbour(rows, 4, "right"), 0); // wraps around
        compare(WindowGrid.neighbour(rows, 0, "left"), 4);
        compare(WindowGrid.neighbour(rows, 1, "down"), 4);
        compare(WindowGrid.neighbour(rows, 2, "down"), 4); // shorter row: its last window
        compare(WindowGrid.neighbour(rows, 4, "up"), 1);
        compare(WindowGrid.neighbour(rows, 1, "up"), 1);   // top row: stays
        compare(WindowGrid.neighbour([], 0, "right"), -1);
    }
}
