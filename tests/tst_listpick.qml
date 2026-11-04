// Tests for the desktop widgets' list picks. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/desktop/ListPick.js" as ListPick

TestCase {
    name: "ListPick"

    function test_step() {
        compare(ListPick.step(-1, 3, true), 0);   // Down from none: the first row
        compare(ListPick.step(1, 3, true), 2);
        compare(ListPick.step(2, 3, true), null); // past the last: on to the next widget
        compare(ListPick.step(0, 3, false), -1);  // Up from the first: none
        compare(ListPick.step(-1, 3, false), null);
        compare(ListPick.step(-1, 0, true), null); // an empty list
    }

    function test_kept() {
        compare(ListPick.kept(2, 3), 2);
        compare(ListPick.kept(2, 2), 1); // the last row went
        compare(ListPick.kept(0, 0), -1);
        compare(ListPick.kept(-1, 5), -1);
    }
}
