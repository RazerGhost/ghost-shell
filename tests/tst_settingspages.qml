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
        compare(SettingsPages.find("power").title, "Lock and power");
        compare(SettingsPages.find("nope"), null);
    }

    function test_aliases() {
        // Pages merged into Lock and power keep their ids.
        compare(SettingsPages.resolve("lock"), "power");
        compare(SettingsPages.resolve("account"), "power");
        compare(SettingsPages.find("account").title, "Lock and power");
        compare(SettingsPages.resolve("display"), "display");
        // Their settings are still found by search.
        compare(SettingsPages.matching("grace period")[0].id, "power");
        compare(SettingsPages.matching("password")[0].id, "power");
        compare(SettingsPages.matching("launcher width")[0].id, "display");
    }
}
