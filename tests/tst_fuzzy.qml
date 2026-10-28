// Tests for the launcher's fuzzy search. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/launcher/Fuzzy.js" as Fuzzy

TestCase {
    name: "Fuzzy"

    // Stand-ins for DesktopEntry objects: only the properties Fuzzy.js reads.
    readonly property var apps: [
        { name: "Zen Browser", genericName: "Web Browser", keywords: ["internet", "web"], noDisplay: false },
        { name: "Files", genericName: "File Manager", keywords: ["folder", "nautilus"], noDisplay: false },
        { name: "Ghostty", genericName: "Terminal", keywords: ["shell", "tty"], noDisplay: false },
        { name: "Profile Editor", genericName: "", keywords: [], noDisplay: false },
        { name: "Hidden Helper", genericName: "", keywords: [], noDisplay: true },
    ]

    // Entries with .desktop actions, for Fuzzy.actions.
    readonly property var withActions: [
        { name: "Zen Browser", noDisplay: false, actions: [{ name: "New Window" }, { name: "New Private Window" }] },
        { name: "Steam", noDisplay: false, actions: [{ name: "Library" }, { name: "Store" }] },
        { name: "Hidden Helper", noDisplay: true, actions: [{ name: "Private Thing" }] },
    ]

    function actionNames(results) {
        return results.map(r => r.entry.name + ": " + r.action.name);
    }

    function test_actionsByName() {
        compare(actionNames(Fuzzy.actions(withActions, "private")), ["Zen Browser: New Private Window"]);
        compare(actionNames(Fuzzy.actions(withActions, "LIB")), ["Steam: Library"]);
    }

    function test_actionsByAppAndName() {
        compare(actionNames(Fuzzy.actions(withActions, "steam st")), ["Steam: Store"]);
    }

    function test_actionsSkipNewWindowAndHidden() {
        compare(actionNames(Fuzzy.actions(withActions, "new")), ["Zen Browser: New Private Window"]);
        compare(Fuzzy.actions(withActions, "thing").length, 0);
    }

    function test_resultsMixAppsAndActions() {
        const entries = withActions.concat([{ name: "Shelly", genericName: "Package Manager", keywords: [], noDisplay: false }]);
        // "private" matches Shelly only loosely, the action by its whole name: the action first.
        const results = Fuzzy.results(entries, "private");
        compare(results[0].action.name, "New Private Window");
        // A good app match still beats a shortcut.
        const steam = Fuzzy.results(entries, "steam");
        compare(steam[0].entry.name, "Steam");
        compare(steam[0].action, null);
        // No query: only the apps, by name.
        compare(Fuzzy.results(entries, "").map(r => r.entry.name), ["Shelly", "Steam", "Zen Browser"]);
    }

    function test_actionsNeedTheQueryAsIs() {
        compare(Fuzzy.actions(withActions, "").length, 0);
        compare(Fuzzy.actions(withActions, "pvt").length, 0); // no loose subsequence matches
    }

    function names(entries) {
        return entries.map(e => e.name);
    }

    function test_noMatch() {
        compare(Fuzzy.score("xyz", "Ghostty"), -1);
        compare(Fuzzy.score("tg", "Ghostty"), -1); // characters out of order
    }

    function test_subsequenceMatches() {
        verify(Fuzzy.score("gsty", "Ghostty") >= 0);
        verify(Fuzzy.score("GHOST", "ghostty") >= 0); // case-insensitive
    }

    function test_prefixBeatsMiddle() {
        verify(Fuzzy.score("fi", "Files") > Fuzzy.score("fi", "Profile Editor"));
    }

    function test_wordStartBeatsScattered() {
        verify(Fuzzy.score("br", "Zen Browser") > Fuzzy.score("br", "Abacus Rover"));
    }

    function test_emptyQueryListsAllAlphabetically() {
        compare(names(Fuzzy.filter(apps, "  ")), ["Files", "Ghostty", "Profile Editor", "Zen Browser"]);
    }

    function test_noDisplayIsHidden() {
        compare(names(Fuzzy.filter(apps, "hidden")), []);
    }

    function test_matchesGenericNameAndKeywords() {
        compare(names(Fuzzy.filter(apps, "terminal"))[0], "Ghostty");
        compare(names(Fuzzy.filter(apps, "nautilus"))[0], "Files");
    }

    function test_bestMatchFirst() {
        compare(names(Fuzzy.filter(apps, "fi"))[0], "Files");
    }
}
