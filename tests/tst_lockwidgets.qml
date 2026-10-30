import QtQuick
import QtTest
import "../quickshell/.config/quickshell/lock/LockWidgets.js" as LockWidgets

TestCase {
    name: "LockWidgets"

    function test_shown() {
        // No list yet: what the old switches showed, in the old order.
        compare(LockWidgets.shown(undefined, { lockWeather: true, lockBattery: true, lockEvent: false,
                                               lockNotificationCount: true }),
                ["weather", "battery", "notifications"]);
        compare(LockWidgets.shown(null, {}), []);
        // Unknown ids and repeats dropped, the order kept, four at most.
        compare(LockWidgets.shown(["todo", "nope", "weather", "todo"], {}), ["todo", "weather"]);
        compare(LockWidgets.shown(["weather", "battery", "notifications", "todo", "event"], {}),
                ["weather", "battery", "notifications", "todo"]);
        // An empty list stays empty (you took them all off).
        compare(LockWidgets.shown([], { lockWeather: true }), []);
    }

    function test_moved() {
        compare(LockWidgets.moved(["weather", "battery", "todo"], 2, 0), ["todo", "weather", "battery"]);
        compare(LockWidgets.moved(["weather", "battery"], 0, 5), ["battery", "weather"]);
        compare(LockWidgets.moved(["weather", "battery"], -1, 0), ["weather", "battery"]);
    }

    function test_toggled() {
        compare(LockWidgets.toggled(["weather"], "todo"), ["weather", "todo"]);
        compare(LockWidgets.toggled(["weather", "todo"], "weather"), ["todo"]);
        // Full: nothing more is added.
        compare(LockWidgets.toggled(["weather", "battery", "notifications", "todo"], "event"),
                ["weather", "battery", "notifications", "todo"]);
        compare(LockWidgets.toggled([], "nope"), []);
    }
}
