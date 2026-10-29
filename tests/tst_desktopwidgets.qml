import QtQuick
import QtTest
import "../quickshell/.config/quickshell/desktop/DesktopWidgets.js" as DesktopWidgets

TestCase {
    name: "DesktopWidgets"

    function test_place() {
        compare(DesktopWidgets.place({}, "clock"), { x: 0.04, y: 0.08 });
        compare(DesktopWidgets.place({ clock: { x: 0.5, y: 0.25 } }, "clock"), { x: 0.5, y: 0.25 });
        // Off the screen or not a number: the default for that coordinate.
        compare(DesktopWidgets.place({ weather: { x: 3, y: "0.1" } }, "weather"), { x: 0.04, y: 0.32 });
        compare(DesktopWidgets.place(undefined, "media"), { x: 0.04, y: 0.46 });
    }

    function test_dropped() {
        compare(DesktopWidgets.dropped(960, 540, 200, 100, 1920, 1080), { x: 0.5, y: 0.5 });
        // Past the right and bottom edges: pulled back so the whole widget shows.
        compare(DesktopWidgets.dropped(1900, 1070, 192, 108, 1920, 1080), { x: 0.9, y: 0.9 });
        compare(DesktopWidgets.dropped(-50, -10, 100, 100, 1000, 1000), { x: 0, y: 0 });
    }
}
