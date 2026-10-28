import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/BatteryTime.js" as BatteryTime

TestCase {
    name: "BatteryTime"

    function test_hoursAndMinutes() {
        compare(BatteryTime.duration(3 * 3600 + 20 * 60), "3h 20m");
        compare(BatteryTime.duration(3600), "1h 0m");
    }

    function test_minutesOnly() {
        compare(BatteryTime.duration(25 * 60), "25m");
        compare(BatteryTime.duration(20), "0m");
    }

    function test_roundingCarriesIntoTheHour() {
        // 1 h 59.5 min: rounding the minutes alone gave "1h 60m".
        compare(BatteryTime.duration(7170), "2h 0m");
        compare(BatteryTime.duration(3570), "1h 0m");
    }
}
