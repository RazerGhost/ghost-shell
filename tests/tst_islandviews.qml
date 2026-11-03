import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/IslandViews.js" as IslandViews

TestCase {
    name: "IslandViews"

    function test_shown() {
        compare(IslandViews.shown("today", ""), "today");
        compare(IslandViews.shown("settings", ""), "settings");
        // The hover view only while no menu is open.
        compare(IslandViews.shown("", "media"), "peek-media");
        compare(IslandViews.shown("settings", "media"), "settings");
        compare(IslandViews.shown("", ""), "");
    }
}
