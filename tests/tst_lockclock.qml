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
}
