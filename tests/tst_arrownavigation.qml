import QtQuick
import QtTest
import "../quickshell/.config/quickshell/widgets/ArrowNavigation.js" as Nav

TestCase {
    name: "ArrowNavigation"

    function rect(x, y, width, height) {
        return { x: x, y: y, width: width, height: height };
    }

    // Quick settings' shape: two wide tiles, two more under them, then four round buttons.
    readonly property var grid: [
        rect(0, 0, 180, 60), rect(190, 0, 180, 60),
        rect(0, 70, 180, 60), rect(190, 70, 180, 60),
        rect(10, 140, 48, 48), rect(110, 140, 48, 48), rect(210, 140, 48, 48), rect(310, 140, 48, 48)
    ]

    function test_grid() {
        compare(Nav.nearest(grid[0], grid, "right"), 1);
        compare(Nav.nearest(grid[0], grid, "down"), 2);
        compare(Nav.nearest(grid[1], grid, "down"), 3);
        compare(Nav.nearest(grid[3], grid, "left"), 2);
        // Down from a wide tile: the round button most in line with it.
        compare(Nav.nearest(grid[3], grid, "down"), 6);
        compare(Nav.nearest(grid[7], grid, "up"), 3);
        compare(Nav.nearest(grid[5], grid, "left"), 4);
    }

    function test_edges() {
        compare(Nav.nearest(grid[0], grid, "up"), -1);
        compare(Nav.nearest(grid[0], grid, "left"), -1);
        compare(Nav.nearest(grid[7], grid, "right"), -1);
        compare(Nav.nearest(grid[7], grid, "down"), -1);
    }

    function test_first() {
        compare(Nav.nearest(null, [rect(100, 50, 10, 10), rect(200, 0, 10, 10), rect(0, 0, 10, 10)], "down"), 2);
        compare(Nav.nearest(null, [], "down"), -1);
    }

    function test_nested() {
        // A list row with a button at its right end, and the row under it.
        const rows = [rect(0, 0, 360, 48), rect(310, 8, 32, 32), rect(0, 52, 360, 48)];
        compare(Nav.nearest(rows[0], rows, "right"), 1);
        compare(Nav.nearest(rows[1], rows, "left"), 0);
        compare(Nav.nearest(rows[0], rows, "down"), 2);
        compare(Nav.nearest(rows[2], rows, "up"), 0);
    }

    function test_out_of_line() {
        // A lone button below and to the side is still reachable, but not sideways.
        const items = [rect(0, 0, 100, 40), rect(150, 200, 40, 40)];
        compare(Nav.nearest(items[0], items, "down"), 1);
        compare(Nav.nearest(items[1], items, "up"), 0);
        compare(Nav.nearest(items[0], items, "right"), -1);
    }
}
