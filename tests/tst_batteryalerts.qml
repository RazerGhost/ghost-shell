import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/BatteryAlerts.js" as BatteryAlerts

TestCase {
    name: "BatteryAlerts"

    function test_warning() {
        compare(BatteryAlerts.warning(0.50, false, "", 0.2, 0.1), "");
        compare(BatteryAlerts.warning(0.20, false, "", 0.2, 0.1), "low");
        compare(BatteryAlerts.warning(0.15, false, "low", 0.2, 0.1), "");          // once
        compare(BatteryAlerts.warning(0.10, false, "low", 0.2, 0.1), "critical");
        compare(BatteryAlerts.warning(0.05, false, "critical", 0.2, 0.1), "");     // once
        compare(BatteryAlerts.warning(0.08, false, "", 0.2, 0.1), "critical");     // started low: straight to critical
        compare(BatteryAlerts.warning(0.05, true, "", 0.2, 0.1), "");              // charging: none
    }
}
