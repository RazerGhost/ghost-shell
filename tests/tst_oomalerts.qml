import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/OomAlerts.js" as OomAlerts

TestCase {
    name: "OomAlerts"

    function entry(identifier, message) {
        return JSON.stringify({ SYSLOG_IDENTIFIER: identifier, MESSAGE: message, __REALTIME_TIMESTAMP: "1761750000000000" });
    }

    function test_kernel() {
        compare(OomAlerts.kill(entry("kernel", "Out of memory: Killed process 4242 (zen-bin) total-vm:9123456kB, anon-rss:812345kB"), 1000),
                { app: "zen-bin", session: false, time: 1761750000000000 });
        compare(OomAlerts.kill(entry("kernel", "Memory cgroup out of memory: Killed process 77 (Isolated Web Co) total-vm:1kB"), 1000).app,
                "Isolated Web Co");
        // Other kernel lines that match the search aren't kills.
        compare(OomAlerts.kill(entry("kernel", "oom_reaper: reaped process 4242 (zen-bin)"), 1000), null);
    }

    function test_oomd() {
        compare(OomAlerts.kill(entry("systemd-oomd", "Killed /user.slice/user-1000.slice/session-3.scope due to memory pressure for /user.slice/user-1000.slice being 81.20% > 80.00% for > 30s with reclaim activity"), 1000),
                { app: "", session: true, time: 1761750000000000 });
        compare(OomAlerts.kill(entry("systemd-oomd", "Killed /user.slice/user-1000.slice/user@1000.service/session.slice/pipewire.service due to swap used being more than 90.00%"), 1000).app,
                "pipewire");
        // The greeter's or another user's session.
        compare(OomAlerts.kill(entry("systemd-oomd", "Killed /user.slice/user-969.slice/session-1.scope due to swap"), 1000), null);
        compare(OomAlerts.kill(entry("systemd-oomd", "Started"), 1000), null);
    }

    function test_other() {
        compare(OomAlerts.kill(entry("bash", "Killed process 1 (x)"), 1000), null);
        compare(OomAlerts.kill("not json", 1000), null);
        // journalctl writes a message that isn't valid UTF-8 as an array of bytes.
        compare(OomAlerts.kill(JSON.stringify({ SYSLOG_IDENTIFIER: "kernel", MESSAGE: [75, 105] }), 1000), null);
    }
}
