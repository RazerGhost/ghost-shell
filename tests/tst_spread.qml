import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/Spread.js" as Spread

TestCase {
    name: "Spread"

    function test_naturalWidth() {
        // The workspace dots: a 16 px pill and four 6 px dots, 3 px apart.
        compare(Spread.naturalWidth([16, 6, 6, 6, 6], 3), 52);
        compare(Spread.naturalWidth([16], 3), 16);
        compare(Spread.naturalWidth([], 3), 0);
    }

    function test_spreadsToFill() {
        // Wi-Fi and battery (16 + 25) filling the dots' 52 px: 11 px between them.
        compare(Spread.spacing([16, 25], 4, 52), 11);
        compare(Spread.naturalWidth([16, 25], 4) + 11 - 4, 52);
    }

    function test_neverTighterThanMinimum() {
        // Asked for less room than the items need: keep the minimum spacing.
        compare(Spread.spacing([16, 6, 6, 6, 6], 3, 30), 3);
    }

    function test_singleItem() {
        compare(Spread.spacing([16], 4, 60), 4);
    }
}
