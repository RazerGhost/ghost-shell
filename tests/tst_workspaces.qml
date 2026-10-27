// Tests for the island's workspace dots. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/WorkspaceSlots.js" as WorkspaceSlots

TestCase {
    name: "WorkspaceSlots"

    function test_minimumDots() {
        compare(WorkspaceSlots.slots(5, []), [1, 2, 3, 4, 5]);
        compare(WorkspaceSlots.slots(5, [1, 3]), [1, 2, 3, 4, 5]);
    }

    function test_growsForHigherWorkspaces() {
        compare(WorkspaceSlots.slots(5, [2, 8]), [1, 2, 3, 4, 5, 6, 7, 8]);
    }

    function test_ignoresSpecialWorkspaces() {
        // The scratchpad has a negative id.
        compare(WorkspaceSlots.slots(5, [-98, 1]), [1, 2, 3, 4, 5]);
    }

    function test_stepWraps() {
        compare(WorkspaceSlots.step(2, 1, 5), 3);
        compare(WorkspaceSlots.step(5, 1, 5), 1);
        compare(WorkspaceSlots.step(1, -1, 5), 5);
    }
}
