import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/QuickItems.js" as QuickItems

TestCase {
    name: "QuickItems"

    function test_shown() {
        // No list yet: the defaults.
        compare(QuickItems.shown(undefined, QuickItems.toggles, QuickItems.defaultToggles), QuickItems.defaultToggles);
        // Unknown ids and repeats are dropped, the order kept.
        compare(QuickItems.shown(["game", "nope", "mic", "game"], QuickItems.toggles, QuickItems.defaultToggles), ["game", "mic"]);
        // An empty list stays empty (you removed them all).
        compare(QuickItems.shown([], QuickItems.tiles, QuickItems.defaultTiles), []);
        compare(QuickItems.shown("wifi", QuickItems.tiles, QuickItems.defaultTiles), QuickItems.defaultTiles);
    }

    function test_available() {
        compare(QuickItems.available(["wifi", "sound"], QuickItems.tiles), ["bluetooth", "power"]);
        compare(QuickItems.available(QuickItems.tiles, QuickItems.tiles), []);
    }

    function test_addedRemoved() {
        compare(QuickItems.added(["mic"], "dark"), ["mic", "dark"]);
        compare(QuickItems.added(["mic"], "mic"), ["mic"]);
        compare(QuickItems.removed(["mic", "dark"], "mic"), ["dark"]);
    }
}
