// Tests for the dock's grouping and click logic. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/dock/DockApps.js" as DockApps

TestCase {
    name: "DockApps"

    // appId -> desktop entry id, like DesktopEntries.heuristicLookup.
    function resolve(appId) {
        return { "zen": "zen", "com.mitchellh.ghostty": "com.mitchellh.ghostty" }[appId] || "";
    }

    function test_pinnedFirstThenRunning() {
        const windows = [{ appId: "com.mitchellh.ghostty" }, { appId: "zen" }, { appId: "zen" }];
        const items = DockApps.items(windows, ["zen", "spotify"], resolve);
        compare(items.map(i => i.id), ["zen", "spotify", "com.mitchellh.ghostty"]);
        compare(items.map(i => i.pinned), [true, true, false]);
        compare(items[0].windows.length, 2);
        compare(items[1].windows.length, 0);
    }

    function test_unknownAppsGroupByAppId() {
        const windows = [{ appId: "qs.test" }, { appId: "qs.test" }];
        const items = DockApps.items(windows, [], resolve);
        compare(items.length, 1);
        compare(items[0].id, "app:qs.test");
        compare(items[0].windows.length, 2);
    }

    function test_clickTarget() {
        const a = { title: "a" }, b = { title: "b" }, c = { title: "c" };
        compare(DockApps.clickTarget([], null), "");
        compare(DockApps.clickTarget([a, b], null), a);       // most recent
        compare(DockApps.clickTarget([a, b, c], a), b);       // cycle
        compare(DockApps.clickTarget([a, b, c], c), a);       // wraps
        compare(DockApps.clickTarget([a], a), "minimize");    // the active app's only window
    }

    function test_notificationCount() {
        const notifications = [
            { desktopEntry: "vesktop", appName: "Vesktop" },
            { desktopEntry: "", appName: "Vesktop" },       // no desktop entry: the name matches
            { desktopEntry: "spotify", appName: "Spotify" },
            { desktopEntry: "", appName: "" }
        ];
        compare(DockApps.notificationCount(notifications, "vesktop", "Vesktop"), 2);
        compare(DockApps.notificationCount(notifications, "spotify", "Spotify"), 1);
        compare(DockApps.notificationCount(notifications, "zen", "Zen Browser"), 0);
        compare(DockApps.notificationCount([], "zen", "Zen Browser"), 0);
    }

    function test_placePin() {
        compare(DockApps.placePin(["zen", "ghostty", "files"], "zen", 2), ["ghostty", "files", "zen"]);
        compare(DockApps.placePin(["zen", "ghostty", "files"], "files", 0), ["files", "zen", "ghostty"]);
        // Not pinned yet: pinned at that place.
        compare(DockApps.placePin(["zen", "ghostty"], "steam", 1), ["zen", "steam", "ghostty"]);
        compare(DockApps.placePin(["zen"], "steam", 9), ["zen", "steam"]);
        compare(DockApps.placePin(["zen"], "steam", -2), ["steam", "zen"]);
    }

    function test_movePin() {
        compare(DockApps.movePin(["zen", "ghostty", "files"], "ghostty", -1), ["ghostty", "zen", "files"]);
        compare(DockApps.movePin(["zen", "ghostty", "files"], "ghostty", 1), ["zen", "files", "ghostty"]);
        compare(DockApps.movePin(["zen", "ghostty"], "zen", -1), ["zen", "ghostty"]); // already first
        compare(DockApps.movePin(["zen"], "steam", 1), ["zen"]); // not pinned
    }
}
