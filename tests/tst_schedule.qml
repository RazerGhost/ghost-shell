import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Schedule.js" as Schedule

TestCase {
    name: "Schedule"

    function test_sameDay() {
        // 09:00 - 17:00
        verify(!Schedule.active(8 * 60 + 59, 540, 1020));
        verify(Schedule.active(540, 540, 1020));
        verify(Schedule.active(16 * 60 + 59, 540, 1020));
        verify(!Schedule.active(1020, 540, 1020)); // the end minute is already off
    }

    function test_overnight() {
        // 20:00 - 07:00
        verify(Schedule.active(1200, 1200, 420));
        verify(Schedule.active(23 * 60 + 59, 1200, 420));
        verify(Schedule.active(0, 1200, 420));
        verify(Schedule.active(419, 1200, 420));
        verify(!Schedule.active(420, 1200, 420));
        verify(!Schedule.active(12 * 60, 1200, 420));
    }

    function test_emptySchedule() {
        verify(!Schedule.active(0, 600, 600));
        verify(!Schedule.active(600, 600, 600));
    }

    function test_minutesOf() {
        compare(Schedule.minutesOf(new Date(2026, 9, 28, 7, 30)), 450);
        compare(Schedule.minutesOf(new Date(2026, 9, 28, 0, 0)), 0);
    }

    function test_format() {
        compare(Schedule.format(450), "07:30");
        compare(Schedule.format(0), "00:00");
        compare(Schedule.format(23 * 60 + 45), "23:45");
    }
}
