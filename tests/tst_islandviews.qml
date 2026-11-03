import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/IslandViews.js" as IslandViews

TestCase {
    name: "IslandViews"

    function test_shown() {
        compare(IslandViews.shown("today", false, false, false, ""), "today");
        compare(IslandViews.shown("settings", false, false, false, ""), "settings");
        // The hover view only while nothing else is shown.
        compare(IslandViews.shown("", false, false, false, "media"), "peek-media");
        compare(IslandViews.shown("settings", false, false, false, "media"), "settings");
        compare(IslandViews.shown("", false, false, false, ""), "");
        // A failed reload's error over the rest, under an open menu.
        compare(IslandViews.shown("", true, true, true, "media"), "reload");
        compare(IslandViews.shown("today", true, false, false, ""), "today");
        // A notification over a window asking for attention, both over the hover view; a menu
        // over both.
        compare(IslandViews.shown("", false, true, true, "media"), "notification");
        compare(IslandViews.shown("", false, false, true, "media"), "attention");
        compare(IslandViews.shown("today", false, true, true, ""), "today");
    }
}
