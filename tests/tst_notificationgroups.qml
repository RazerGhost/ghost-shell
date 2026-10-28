import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/NotificationGroups.js" as NotificationGroups

TestCase {
    name: "NotificationGroups"

    function test_groups() {
        compare(NotificationGroups.groups(["Vesktop", "Spotify", "Vesktop", "", "Vesktop"]), [
            { app: "Vesktop", indices: [0, 2, 4] },
            { app: "Spotify", indices: [1] },
            { app: "", indices: [3] }
        ]);
        compare(NotificationGroups.groups([]), []);
    }
}
