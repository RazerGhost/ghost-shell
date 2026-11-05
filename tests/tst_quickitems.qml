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
        // A list read back from settings.json is array-like, not an Array.
        compare(QuickItems.shown({ 0: "phone", 1: "wifi", length: 2 }, QuickItems.tiles, []), ["phone", "wifi"]);
    }

    function test_available() {
        compare(QuickItems.available(["wifi", "sound"], QuickItems.tiles), ["bluetooth", "power", "phone", "display"]);
        compare(QuickItems.available(QuickItems.tiles, QuickItems.tiles), []);
    }

    function test_addedRemoved() {
        compare(QuickItems.added(["mic"], "dark"), ["mic", "dark"]);
        compare(QuickItems.added(["mic"], "mic"), ["mic"]);
        compare(QuickItems.removed(["mic", "dark"], "mic"), ["dark"]);
    }

    function test_fullRow() {
        // All small: pairs, and an odd one out at the end takes the row.
        compare(QuickItems.fullRow(["wifi", "bluetooth", "sound"], []), ["sound"]);
        compare(QuickItems.fullRow(["wifi", "bluetooth"], []), []);
        // A large one takes its row, and a small one before it has nothing to pair with.
        compare(QuickItems.fullRow(["wifi", "phone", "sound", "power"], ["phone"]), ["wifi", "phone"]);
        compare(QuickItems.fullRow(["phone", "wifi", "sound"], ["phone"]), ["phone"]);
        compare(QuickItems.fullRow([], ["phone"]), []);
    }

    function test_columns() {
        // Five buttons: five places, even with room for six.
        compare(QuickItems.columns(5, 428, 52, 16), 5);
        // More buttons: as many as fit.
        compare(QuickItems.columns(7, 428, 52, 16), 6);
        compare(QuickItems.columns(9, 348, 52, 16), 5);
        // Fewer than five keep five places.
        compare(QuickItems.columns(3, 428, 52, 16), 5);
    }

    function test_toggled() {
        compare(QuickItems.toggled([], "phone"), ["phone"]);
        compare(QuickItems.toggled(["phone", "wifi"], "phone"), ["wifi"]);
    }
}
