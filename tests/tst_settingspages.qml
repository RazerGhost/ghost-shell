import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/SettingsPages.js" as SettingsPages

TestCase {
    name: "SettingsPages"

    function test_matching() {
        compare(SettingsPages.matching("").length, SettingsPages.pages.length);
        // A title match comes before a page that only has the word.
        const sound = SettingsPages.matching("sound");
        compare(sound[0].id, "sound");
        // Words find the page for a setting on it.
        compare(SettingsPages.matching("refresh rate")[0].id, "display");
        compare(SettingsPages.matching("REFRESH")[0].id, "display");
        compare(SettingsPages.matching("zzz"), []);
    }

    function test_find() {
        compare(SettingsPages.find("lock").title, "Lock screen");
        compare(SettingsPages.find("nope"), null);
    }
}
