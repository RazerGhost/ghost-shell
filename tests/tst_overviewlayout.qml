import QtQuick
import QtTest
import "../quickshell/.config/quickshell/overview/OverviewLayout.js" as OverviewLayout

TestCase {
    name: "OverviewLayout"

    function test_empty() {
        compare(OverviewLayout.grid([], 1000, 800, 20, 30), []);
    }

    function test_singleWindowKeepsShapeAndFits() {
        const rows = OverviewLayout.grid([{ width: 1600, height: 900 }], 1000, 800, 20, 30);
        compare(rows.length, 1);
        const w = rows[0][0];
        compare(w.width, 1000);       // as wide as the area
        compare(w.height, 562);       // 16:9 kept (1000 / 1.777, floored)
    }

    function test_neverLargerThanTheWindow() {
        const rows = OverviewLayout.grid([{ width: 400, height: 300 }], 1800, 900, 20, 30);
        compare(rows[0][0].width, 400);
        compare(rows[0][0].height, 300);
    }

    function test_fourWindowsMakeTwoRows() {
        const windows = [];
        for (let i = 0; i < 4; i++)
            windows.push({ width: 1600, height: 900 });
        const rows = OverviewLayout.grid(windows, 1800, 900, 20, 30);
        compare(rows.length, 2);
        compare(rows[0].length, 2);
        compare(rows[1][1].index, 3);
    }

    function test_wideAreaPutsTwoSideBySide() {
        const rows = OverviewLayout.grid([{ width: 800, height: 800 }, { width: 800, height: 800 }], 1800, 600, 20, 30);
        compare(rows.length, 1);
        compare(rows[0].length, 2);
    }
}
