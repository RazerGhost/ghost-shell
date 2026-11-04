// Tests for the snap spots' pictures. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
// (tests/tiling_test.lua checks that Hyprland's layout knows the same spots.)
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/SnapLayout.js" as SnapLayout

TestCase {
    name: "SnapLayout"

    function test_layout() {
        compare(SnapLayout.layout("right"), { cols: 2, rows: 1, col: 1, row: 0 });
        compare(SnapLayout.layout("left-two-thirds").span, 2);
    }

    function test_unknownThrows() {
        let threw = false;
        try {
            SnapLayout.layout("diagonal");
        } catch (e) {
            threw = true;
        }
        verify(threw);
    }

    function test_nextSpot() {
        compare(SnapLayout.nextSpot("left", "up"), "top-left");
        compare(SnapLayout.nextSpot("right", "down"), "bottom-right");
        compare(SnapLayout.nextSpot("top-left", "down"), "left");
        compare(SnapLayout.nextSpot("bottom-right", "up"), "right");
        compare(SnapLayout.nextSpot("top-left", "up"), null); // a top quarter: Up maximizes
        compare(SnapLayout.nextSpot("", "up"), null);
        compare(SnapLayout.nextSpot("left-third", "down"), null);
    }

    // Super+Up / Down only step from a spot the window is still in.
    function test_holds() {
        const area = { x: 0, y: 0, w: 1920, h: 1080 };
        compare(SnapLayout.holds("left", { x: 10, y: 46, w: 945, h: 1024 }, area), true);
        compare(SnapLayout.holds("left", { x: 965, y: 46, w: 945, h: 1024 }, area), false); // swapped right
        compare(SnapLayout.holds("top-right", { x: 965, y: 46, w: 945, h: 500 }, area), true);
        compare(SnapLayout.holds("top-right", { x: 965, y: 560, w: 945, h: 500 }, area), false);
        compare(SnapLayout.holds("left-two-thirds", { x: 10, y: 46, w: 1260, h: 1024 }, area), true);
        // A second screen to the right.
        compare(SnapLayout.holds("right", { x: 2900, y: 46, w: 945, h: 1024 }, { x: 1920, y: 0, w: 1920, h: 1080 }), true);
        compare(SnapLayout.holds("nowhere", { x: 0, y: 0, w: 10, h: 10 }, area), false);
        compare(SnapLayout.holds("left", null, area), false);
    }
}
