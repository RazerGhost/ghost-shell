import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/IslandViews.js" as IslandViews

TestCase {
    name: "IslandViews"

    function test_shown() {
        compare(IslandViews.shown("today", false, ""), "today");
        compare(IslandViews.shown("settings", false, ""), "settings");
        // The hover view only while no menu is open.
        compare(IslandViews.shown("", false, "media"), "peek-media");
        compare(IslandViews.shown("settings", false, "media"), "settings");
        compare(IslandViews.shown("", false, ""), "");
        // A failed reload's error over the hover view, under an open menu.
        compare(IslandViews.shown("", true, "media"), "reload");
        compare(IslandViews.shown("today", true, ""), "today");
    }
}
