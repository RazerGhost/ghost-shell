import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/IslandViews.js" as IslandViews

TestCase {
    name: "IslandViews"

    function test_order() {
        // An open menu beats everything.
        compare(IslandViews.shown("today", true, true, true, "media"), "today");
        compare(IslandViews.shown("", true, true, true, "media"), "reload");
        compare(IslandViews.shown("", false, true, true, "media"), "notification");
        compare(IslandViews.shown("", false, false, true, "media"), "attention");
        compare(IslandViews.shown("", false, false, false, "workspaces"), "peek-workspaces");
        compare(IslandViews.shown("", false, false, false, ""), "");
    }
}
