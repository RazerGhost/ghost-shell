// Tests for the media menu's time labels. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/TrackTime.js" as TrackTime

TestCase {
    name: "TrackTime"

    function test_minutes() {
        compare(TrackTime.format(0), "0:00");
        compare(TrackTime.format(7.9), "0:07"); // rounds down, like a player's clock
        compare(TrackTime.format(187), "3:07");
    }

    function test_hours() {
        compare(TrackTime.format(3723), "1:02:03");
    }

    function test_negative() {
        compare(TrackTime.format(-5), "0:00");
    }
}
