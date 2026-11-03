import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/IslandViews.js" as IslandViews

TestCase {
    name: "IslandViews"

    function test_side() {
        compare(IslandViews.side("settings"), "right");
        compare(IslandViews.side("power"), "right");
        compare(IslandViews.side("today"), "center");
        compare(IslandViews.side("emoji"), "center");
        compare(IslandViews.side(""), "");
        compare(IslandViews.side("nonsense"), "");
    }

    function test_shown() {
        // A pill shows its own menu; another pill's menu leaves it closed.
        compare(IslandViews.shown("center", "today", ""), "today");
        compare(IslandViews.shown("right", "today", ""), "");
        compare(IslandViews.shown("right", "settings", ""), "settings");
        // Hover views only while no menu is open.
        compare(IslandViews.shown("center", "", "media"), "peek-media");
        compare(IslandViews.shown("left", "", "workspaces"), "peek-workspaces");
        compare(IslandViews.shown("left", "settings", "workspaces"), "");
        compare(IslandViews.shown("center", "", ""), "");
    }
}
