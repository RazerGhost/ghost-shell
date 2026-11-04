import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/IslandViews.js" as IslandViews

TestCase {
    name: "IslandViews"

    function test_shown() {
        compare(IslandViews.shown("today", false, false, false, false, ""), "today");
        compare(IslandViews.shown("settings", false, false, false, false, ""), "settings");
        // The hover view only while nothing else is shown.
        compare(IslandViews.shown("", false, false, false, false, "media"), "peek-media");
        compare(IslandViews.shown("settings", false, false, false, false, "media"), "settings");
        compare(IslandViews.shown("", false, false, false, false, ""), "");
        // A failed reload's error over the rest, under an open menu.
        compare(IslandViews.shown("", true, false, true, true, "media"), "reload");
        compare(IslandViews.shown("today", true, false, false, false, ""), "today");
        // A notification over a window asking for attention, both over the hover view; a menu
        // over both.
        compare(IslandViews.shown("", false, false, true, true, "media"), "notification");
        compare(IslandViews.shown("", false, false, false, true, "media"), "attention");
        compare(IslandViews.shown("today", false, false, true, true, ""), "today");
        // The greeting after an unlock over notifications (they wait for it), under a menu and
        // a failed reload.
        compare(IslandViews.shown("", false, true, true, true, "media"), "welcome");
        compare(IslandViews.shown("today", false, true, false, false, ""), "today");
        compare(IslandViews.shown("", true, true, false, false, ""), "reload");
    }
}
