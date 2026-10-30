import QtQuick
import QtTest
import "../quickshell/.config/quickshell/widgets/OrderedList.js" as OrderedList

TestCase {
    name: "OrderedList"

    function test_moved() {
        compare(OrderedList.moved(["a", "b", "c", "d"], 0, 2), ["b", "c", "a", "d"]);
        compare(OrderedList.moved(["a", "b", "c", "d"], 3, 0), ["d", "a", "b", "c"]);
        // Past the ends: clamped; from outside the list: unchanged.
        compare(OrderedList.moved(["a", "b", "c"], 1, 9), ["a", "c", "b"]);
        compare(OrderedList.moved(["a", "b"], 5, 0), ["a", "b"]);
        compare(OrderedList.moved(["a", "b"], -1, 0), ["a", "b"]);
    }

    function test_placed() {
        compare(OrderedList.placed(["zen", "ghostty", "files"], "zen", 2), ["ghostty", "files", "zen"]);
        compare(OrderedList.placed(["zen", "ghostty", "files"], "files", 0), ["files", "zen", "ghostty"]);
        // Not in the list yet: put at that place.
        compare(OrderedList.placed(["zen", "ghostty"], "steam", 1), ["zen", "steam", "ghostty"]);
        compare(OrderedList.placed(["zen"], "steam", 9), ["zen", "steam"]);
        compare(OrderedList.placed(["zen"], "steam", -2), ["steam", "zen"]);
    }
}
