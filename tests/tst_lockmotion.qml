import QtQuick
import QtTest
import "../quickshell/.config/quickshell/lock/LockMotion.js" as LockMotion

TestCase {
    name: "LockMotion"

    function test_moved() {
        // Before the pointer showed up: nothing counts.
        verify(!LockMotion.moved({ x: -1, y: -1 }, { x: 500, y: 500 }, 24));
        // Small moves (a brush of the touchpad) don't; past the limit does.
        verify(!LockMotion.moved({ x: 100, y: 100 }, { x: 110, y: 112 }, 24));
        verify(!LockMotion.moved({ x: 100, y: 100 }, { x: 112, y: 112 }, 24));
        verify(LockMotion.moved({ x: 100, y: 100 }, { x: 113, y: 112 }, 24));
        verify(LockMotion.moved({ x: 0, y: 0 }, { x: 0, y: 30 }, 24));
    }
}
