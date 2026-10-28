// Tests for notification time labels. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/NotificationTime.js" as NotificationTime

TestCase {
    name: "NotificationTime"

    readonly property real received: new Date(2026, 9, 28, 14, 2).getTime()

    function test_now() {
        compare(NotificationTime.format(received, received + 59 * 1000), "now");
    }

    function test_minutes() {
        compare(NotificationTime.format(received, received + 5 * 60000), "5 min");
        compare(NotificationTime.format(received, received + 59 * 60000), "59 min");
    }

    function test_clockTime() {
        compare(NotificationTime.format(received, received + 60 * 60000), "14:02");
        compare(NotificationTime.format(new Date(2026, 9, 28, 9, 5).getTime(), received), "09:05");
    }
}
