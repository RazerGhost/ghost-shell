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
