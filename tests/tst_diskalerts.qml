import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/DiskAlerts.js" as DiskAlerts

TestCase {
    name: "DiskAlerts"

    function test_parse() {
        compare(DiskAlerts.parse("       Avail    1B-blocks\n480991121408 509500452864\n"), { avail: 480991121408, size: 509500452864 });
        compare(DiskAlerts.parse("df: /: No such file or directory\n"), null);
    }

    function test_check() {
        // Plenty of room: nothing, and an earlier warning is forgotten.
        compare(DiskAlerts.check(50, 100, "low"), { warning: "", given: "" });
        compare(DiskAlerts.check(9, 100, ""), { warning: "low", given: "low" });
        // Once per shortage: still low, or between low and clear, says nothing more.
        compare(DiskAlerts.check(8, 100, "low"), { warning: "", given: "low" });
        compare(DiskAlerts.check(12, 100, "low"), { warning: "", given: "low" });
        compare(DiskAlerts.check(4, 100, "low"), { warning: "critical", given: "critical" });
        compare(DiskAlerts.check(3, 100, "critical"), { warning: "", given: "critical" });
        // Straight to critical.
        compare(DiskAlerts.check(2, 100, ""), { warning: "critical", given: "critical" });
    }

    function test_size() {
        compare(DiskAlerts.size(42.4e9), "42 GB");
        compare(DiskAlerts.size(512e6), "512 MB");
    }
}
