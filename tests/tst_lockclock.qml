import QtQuick
import QtTest
import "../quickshell/.config/quickshell/lock/LockClock.js" as LockClock

TestCase {
    name: "LockClock"

    function test_pick() {
        compare(LockClock.pick("analog", LockClock.styles), "analog");
        compare(LockClock.pick("huge", LockClock.styles), "big");
        compare(LockClock.pick(undefined, LockClock.layouts), "top");
        compare(LockClock.pick(125, LockClock.sizes), 125);
        compare(LockClock.pick("125", LockClock.sizes), 75);
    }

    function test_digits() {
        const morning = new Date(2026, 9, 29, 9, 5);
        compare(LockClock.digits(morning, true), { hours: "09", minutes: "05", suffix: "" });
        compare(LockClock.digits(morning, false), { hours: "9", minutes: "05", suffix: "AM" });
        compare(LockClock.digits(new Date(2026, 9, 29, 0, 30), false).hours, "12");
        compare(LockClock.digits(new Date(2026, 9, 29, 12, 0), false), { hours: "12", minutes: "00", suffix: "PM" });
        compare(LockClock.digits(new Date(2026, 9, 29, 23, 59), false), { hours: "11", minutes: "59", suffix: "PM" });
    }

    function test_hands() {
        compare(LockClock.hands(new Date(2026, 9, 29, 0, 0)), { hour: 0, minute: 0 });
        compare(LockClock.hands(new Date(2026, 9, 29, 3, 0)), { hour: 90, minute: 0 });
        compare(LockClock.hands(new Date(2026, 9, 29, 15, 30)), { hour: 105, minute: 180 });
    }

    function test_offset() {
        compare(LockClock.offset(null), { x: 0, y: 0 });
        compare(LockClock.offset({ x: 0.1, y: -0.2 }), { x: 0.1, y: -0.2 });
        compare(LockClock.offset({ x: 3, y: 0 }), { x: 0, y: 0 });
        compare(LockClock.offset({ x: "0.1", y: 0 }), { x: 0, y: 0 });
    }

    function test_clamped() {
        // A 400 x 200 column at (760, 200) on a 1920 x 1080 screen; the field at (790, 800), 340 x 40.
        const rect = { x: 760, y: 200, width: 400, height: 200 };
        const field = { x: 790, y: 800, width: 340, height: 40 };
        compare(LockClock.clamped(rect, 100, 50, 1920, 1080, field, 32, 24), { x: 100, y: 50 });
        // Off the left and top edges: kept at the margin.
        compare(LockClock.clamped(rect, -2000, -500, 1920, 1080, field, 32, 24), { x: -728, y: -168 });
        // Onto the field: stops just above it (800 - 24 - 200 = 576).
        compare(LockClock.clamped(rect, 0, 500, 1920, 1080, field, 32, 24), { x: 0, y: 376 });
        // Beside the field (far left), it may go down to the bottom margin.
        compare(LockClock.clamped(rect, -700, 500, 1920, 1080, field, 32, 24), { x: -700, y: 500 });
        // The login screen's power buttons at the bottom right: kept above them there, not
        // beside them.
        const buttons = { x: 1700, y: 1000, width: 180, height: 48 };
        // Dragged down to the bottom right: stops above the buttons (1000 - 24 - 200 = 776).
        compare(LockClock.clamped(rect, 800, 800, 1920, 1080, [field, buttons], 32, 24), { x: 728, y: 576 });
        // At the bottom left, beside them: down to the bottom margin (1080 - 32 - 200 = 848).
        compare(LockClock.clamped(rect, -700, 800, 1920, 1080, [field, buttons], 32, 24), { x: -700, y: 648 });
    }
}
