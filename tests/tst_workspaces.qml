// Tests for the island's workspace dots. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/WorkspaceSlots.js" as WorkspaceSlots

TestCase {
    name: "WorkspaceSlots"

    function test_minimumDots() {
        compare(WorkspaceSlots.slots(5, []), [1, 2, 3, 4, 5]);
        compare(WorkspaceSlots.slots(5, [1, 3]), [1, 2, 3, 4, 5]);
    }

    function test_growsForHigherWorkspaces() {
        compare(WorkspaceSlots.slots(5, [2, 8]), [1, 2, 3, 4, 5, 6, 7, 8]);
    }

    function test_stepIn() {
        // Only the used ones shown: steps between them, wrapping.
        compare(WorkspaceSlots.stepIn([2, 5, 8], 5, 1), 8);
        compare(WorkspaceSlots.stepIn([2, 5, 8], 8, 1), 2);
        compare(WorkspaceSlots.stepIn([2, 5, 8], 2, -1), 8);
        // The same as step() for 1..n.
        compare(WorkspaceSlots.stepIn([1, 2, 3, 4, 5], 5, 1), 1);
        compare(WorkspaceSlots.stepIn([], 3, 1), 3);
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

    function test_usedOnlyExistingAndActive() {
        compare(WorkspaceSlots.used([1, 3], 1), [1, 3]);
        // The active workspace shows even while empty (it may not exist yet).
        compare(WorkspaceSlots.used([1, 3], 2), [1, 2, 3]);
        compare(WorkspaceSlots.used([], 1), [1]);
    }

    function test_usedSortedAndSkipsSpecial() {
        // Special workspaces (minimized windows, scratchpad) have negative ids.
        compare(WorkspaceSlots.used([8, -98, 2], 2), [2, 8]);
    }
}
