import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/SnapshotList.js" as SnapshotList

TestCase {
    name: "SnapshotList"

    readonly property var answer: ({ root: [
        { number: 0, type: "single", date: "", description: "current", cleanup: "" },
        { number: 77, type: "pre", date: "2026-10-28 19:32:26", description: "pacman -Syu", cleanup: "number" },
        { number: 78, type: "post", date: "2026-10-28 19:33:00", description: "linux mesa", cleanup: "number" },
        { number: 79, type: "pre", date: "2026-10-28 22:37:32", description: "pacman -S --needed udiskie libqalculate", cleanup: "number" },
        { number: 80, type: "post", date: "2026-10-28 22:37:36", description: "udiskie libqalculate", cleanup: "number" }
    ] })

    function test_rows() {
        compare(SnapshotList.rows(answer, "root", 5), [
            { number: 79, date: "2026-10-28 22:37:32", label: "Installed: udiskie libqalculate" },
            { number: 77, date: "2026-10-28 19:32:26", label: "System update" }
        ]);
        compare(SnapshotList.rows(answer, "root", 1).length, 1);
        compare(SnapshotList.rows({}, "home", 5), []);
    }

    function test_label() {
        compare(SnapshotList.label({ description: "pacman -Rns showtime decibels", cleanup: "number" }), "Removed: showtime decibels");
        compare(SnapshotList.label({ description: "timeline", cleanup: "timeline" }), "Hourly");
        compare(SnapshotList.label({ description: "By hand", cleanup: "number" }), "By hand");
        compare(SnapshotList.label({ description: "pacman -U /tmp/tmp.x/haunt-bin-0.2.0-1-x86_64.pkg.tar.zst" }), "Installed: haunt-bin-0.2.0-1");
        compare(SnapshotList.label({ description: "pacman -S --needed" }), "Packages changed"); // snap-pac cut it short
        compare(SnapshotList.label({ description: "pacman --sync -y -u --" }), "System update");
    }
}
