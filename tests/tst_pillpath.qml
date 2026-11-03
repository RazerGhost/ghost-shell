import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/PillPath.js" as PillPath

TestCase {
    name: "PillPath"

    function test_float() {
        compare(PillPath.path("float", 100, 36, 18, 14),
                "M 18 0 L 82 0 A 18 18 0 0 1 100 18 L 100 18 A 18 18 0 0 1 82 36 L 18 36 A 18 18 0 0 1 0 18 L 0 18 A 18 18 0 0 1 18 0 Z");
        compare(PillPath.size("float", 100, 36, 14), { width: 100, height: 36, bodyX: 0 });
    }

    function test_top() {
        // Fillets sweep the other way (0) from the rounded corners (1).
        compare(PillPath.path("top", 100, 36, 18, 14),
                "M 0 0 L 128 0 A 14 14 0 0 0 114 14 L 114 18 A 18 18 0 0 1 96 36 L 32 36 A 18 18 0 0 1 14 18 L 14 14 A 14 14 0 0 0 0 0 Z");
        compare(PillPath.size("top", 100, 36, 14), { width: 128, height: 36, bodyX: 14 });
    }

    function test_corners() {
        // Against the left edge: only the inner bottom corner is round; the fillet below runs
        // into the left edge at the shape's bottom.
        compare(PillPath.path("left", 100, 36, 18, 14),
                "M 0 0 L 114 0 A 14 14 0 0 0 100 14 L 100 18 A 18 18 0 0 1 82 36 L 14 36 A 14 14 0 0 0 0 50 Z");
        compare(PillPath.path("right", 100, 36, 18, 14),
                "M 0 0 L 114 0 L 114 50 A 14 14 0 0 0 100 36 L 32 36 A 18 18 0 0 1 14 18 L 14 14 A 14 14 0 0 0 0 0 Z");
        compare(PillPath.size("right", 100, 36, 14), { width: 114, height: 50, bodyX: 14 });
    }

    function test_radiusFits() {
        // Never larger than the body (or than leaves room for a corner pill's fillets).
        compare(PillPath.radius("float", 30, 36, 32, 14), 15);
        compare(PillPath.radius("left", 400, 30, 32, 14), 16);
        compare(PillPath.radius("top", 400, 600, 32, 14), 32);
    }
}
