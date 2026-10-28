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
}
