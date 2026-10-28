// Tests for snap layout rectangles. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/SnapLayout.js" as SnapLayout

TestCase {
    name: "SnapLayout"

    // The laptop: 1920x1080 with the island reserving 36 px at the top, gaps 20 out / 5 in.
    readonly property var area: ({ x: 0, y: 36, width: 1920, height: 1044 })
    readonly property var gapsOut: SnapLayout.parseGaps("20 20 20 20")

    function test_parseGaps() {
        compare(SnapLayout.parseGaps("20"), { top: 20, right: 20, bottom: 20, left: 20 });
        compare(SnapLayout.parseGaps("10 30"), { top: 10, right: 30, bottom: 10, left: 30 });
        compare(SnapLayout.parseGaps("1 2 3 4"), { top: 1, right: 2, bottom: 3, left: 4 });
    }

    function test_fitTooBigWindow() {
        const left = SnapLayout.rect("left", area, gapsOut, 5);    // x 20, 935 wide
        const right = SnapLayout.rect("right", area, gapsOut, 5);  // x 965, 935 wide
        // A window that won't go below 972 px: the left half keeps its edge, the right half grows left.
        compare(SnapLayout.fit("left", left, 972, 1004), { x: 20, y: 56 });
        compare(SnapLayout.fit("right", right, 972, 1004), { x: 965 - 37, y: 56 });
        // The center third grows both ways.
        const center = SnapLayout.rect("center-third", area, gapsOut, 5);
        compare(SnapLayout.fit("center-third", center, center.width + 40, center.height).x, center.x - 20);
        // A bottom quarter that's too tall grows up.
        const quarter = SnapLayout.rect("bottom-right", area, gapsOut, 5);
        compare(SnapLayout.fit("bottom-right", quarter, quarter.width, quarter.height + 30).y, quarter.y - 30);
        // A window that fits stays exactly in its rectangle.
        compare(SnapLayout.fit("right", right, 935, 1004), { x: 965, y: 56 });
    }

    function test_trimNextToTooBigWindow() {
        const left = SnapLayout.rect("left", area, gapsOut, 5);
        const right = SnapLayout.rect("right", area, gapsOut, 5);
        // A window that won't go below 972 px (Discord) on the left ends at 992: the right half starts a gap later.
        const tooWideLeft = { x: 20, y: 56, width: 972, height: 1004 };
        compare(SnapLayout.trim(right, tooWideLeft, 10), { x: 1002, y: 56, width: 898, height: 1004 });
        // The same window on the right starts at 928: the left half ends a gap before.
        const tooWideRight = { x: 928, y: 56, width: 972, height: 1004 };
        compare(SnapLayout.trim(left, tooWideRight, 10), { x: 20, y: 56, width: 898, height: 1004 });
        // A neighbour that fits leaves the rectangle as it is.
        compare(SnapLayout.trim(right, left, 10), right);
        // Stacked quarters: a too-tall top quarter pushes the bottom one down.
        const bottom = SnapLayout.rect("bottom-left", area, gapsOut, 5);
        const tallTop = { x: 20, y: 56, width: 935, height: 530 };
        compare(SnapLayout.trim(bottom, tallTop, 10).y, 596);
        compare(SnapLayout.trim(bottom, tallTop, 10).height, bottom.y + bottom.height - 596);
        // Diagonal quarters don't touch.
        const topRight = SnapLayout.rect("top-right", area, gapsOut, 5);
        compare(SnapLayout.trim(bottom, topRight, 10), bottom);
    }

    function test_halves() {
        compare(SnapLayout.rect("left", area, gapsOut, 5), { x: 20, y: 56, width: 935, height: 1004 });
        compare(SnapLayout.rect("right", area, gapsOut, 5), { x: 965, y: 56, width: 935, height: 1004 });
    }

    function test_quarters() {
        compare(SnapLayout.rect("top-left", area, gapsOut, 5), { x: 20, y: 56, width: 935, height: 497 });
        compare(SnapLayout.rect("bottom-right", area, gapsOut, 5), { x: 965, y: 563, width: 935, height: 497 });
    }

    function test_thirds() {
        // 1880 wide, two 10 px gaps: three columns of 620.
        compare(SnapLayout.rect("left-third", area, gapsOut, 5).width, 620);
        compare(SnapLayout.rect("center-third", area, gapsOut, 5).x, 650);
        compare(SnapLayout.rect("right-two-thirds", area, gapsOut, 5), { x: 650, y: 56, width: 1250, height: 1004 });
    }

    function test_offsetMonitor() {
        // A second monitor to the right starts at x = 1920.
        const r = SnapLayout.rect("left", { x: 1920, y: 0, width: 2560, height: 1440 }, gapsOut, 5);
        compare(r.x, 1940);
        compare(r.y, 20);
    }

    function test_complement() {
        compare(SnapLayout.complement("left"), "right");
        compare(SnapLayout.complement("left-third"), "right-two-thirds");
        compare(SnapLayout.complement("right-two-thirds"), "left-third");
        compare(SnapLayout.complement("top-left"), "");
        compare(SnapLayout.complement("center-third"), "");
    }

    function test_complementsFillTheScreen() {
        // A layout and its complement leave exactly one gap between them.
        const a = SnapLayout.rect("left-third", area, gapsOut, 5);
        const b = SnapLayout.rect("right-two-thirds", area, gapsOut, 5);
        compare(b.x - (a.x + a.width), 10);
        compare(b.x + b.width, 1900);
    }

    function test_unknownThrows() {
        let threw = false;
        try {
            SnapLayout.rect("diagonal", area, gapsOut, 5);
        } catch (e) {
            threw = true;
        }
        verify(threw);
    }
}
