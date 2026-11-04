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

    function test_favoritesHiddenAndCommands() {
        const entries = [{ id: "zen", name: "Zen Browser", keywords: [], noDisplay: false, actions: [] },
                         { id: "steam", name: "Steam", keywords: [], noDisplay: false, actions: [] },
                         { id: "avahi", name: "Avahi Browser", keywords: [], noDisplay: false, actions: [] }];
        const options = { favorites: ["zen"], hidden: ["avahi"],
                          commands: [{ name: "Wallpaper random", command: "ghost theme" }, { name: 3 }] };
        // No query: favorites first, hidden apps gone.
        compare(Fuzzy.results(entries, "", [], options).map(r => r.entry.name), ["Zen Browser", "Steam"]);
        // A hidden app isn't found by name either.
        compare(Fuzzy.results(entries, "avahi", [], options).length, 0);
        // Your commands are found by name; a broken one (no command) is left out.
        const found = Fuzzy.results(entries, "wallp", [], options);
        compare(found.length, 1);
        compare(found[0].custom.command, "ghost theme");
        // The shell's own entries open a launcher page instead of a command.
        const pages = Fuzzy.results(entries, "wallp", [], { commands: [{ name: "Wallpapers", page: "wallpapers" }] });
        compare(pages.length, 1);
        compare(pages[0].custom.page, "wallpapers");
        // Without options, as before.
        compare(Fuzzy.results(entries, "").length, 3);
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

    function test_resultsWithWindows() {
        const windows = [{ window: "w1", title: "Invoice.pdf - Papers", app: "Papers" },
                         { window: "w2", title: "~/dotfiles", app: "Ghostty" }];
        const results = Fuzzy.results(withActions, "invoice", windows);
        compare(results.length, 1);
        compare(results[0].window, "w1");
        compare(results[0].entry, null);
        // An app and its window match equally: the app first.
        const steamWindow = [{ window: "w3", title: "Steam", app: "Steam" }];
        const steam = Fuzzy.results(withActions, "steam", steamWindow);
        compare(steam[0].entry.name, "Steam");
        verify(steam.some(r => r.window === "w3"));
        // Loose matches don't list windows.
        compare(Fuzzy.scoredWindows(windows, "ivc").length, 0);
        compare(Fuzzy.results(withActions, "", windows).filter(r => r.window).length, 0);
    }

    function test_mode() {
        compare(Fuzzy.mode(": smile"), { mode: "emoji", text: "smile" });
        compare(Fuzzy.mode(":"), { mode: "emoji", text: "" });
        compare(Fuzzy.mode("12:30"), { mode: "apps", text: "12:30" }); // a time is no emoji search
        compare(Fuzzy.mode("/ report"), { mode: "files", text: "report" });
        compare(Fuzzy.mode("  >htop -d 5"), { mode: "command", text: "htop -d 5" });
        compare(Fuzzy.mode("zen"), { mode: "apps", text: "zen" });
    }

    function test_files() {
        const found = Fuzzy.files("/home/me/Documents/work/old/report.pdf\n/home/me/report.txt\n/home/me/Reports/\n/mnt/x/report\n", "/home/me");
        compare(found.map(f => f.name), ["report.txt", "Reports", "report", "report.pdf"]);
        compare(found[0].folder, "~/");
        compare(found[2].folder, "/mnt/x/");
        compare(found[3].folder, "~/Documents/work/old/");
        compare(Fuzzy.fileIcon("report.pdf"), "application-pdf");
        compare(Fuzzy.fileIcon("Photo.JPG"), "image-x-generic");
        compare(Fuzzy.fileIcon("Reports"), "folder");
        compare(Fuzzy.fileIcon("notes.md"), "text-x-generic");
        compare(Fuzzy.fileIcon(".bashrc"), "folder"); // hidden files aren't searched
    }

    function test_typos() {
        const apps = [{ name: "Spotify", genericName: "", keywords: [], noDisplay: false },
                      { name: "Zen Browser", genericName: "", keywords: [], noDisplay: false }];
        compare(Fuzzy.results(apps, "sptofiy").length, 0); // two typos: nothing
        compare(Fuzzy.results(apps, "spotfy")[0].entry.name, "Spotify");   // a letter missing
        compare(Fuzzy.results(apps, "spoitfy")[0].entry.name, "Spotify");  // two swapped
        compare(Fuzzy.results(apps, "browsr")[0].entry.name, "Zen Browser");
        verify(Fuzzy.oneTypo("abcd", "abxd"));
        verify(!Fuzzy.oneTypo("abcd", "axyd"));
    }

    function test_color() {
        compare(Fuzzy.color("#FF8800"), "#ff8800");
        compare(Fuzzy.color("#f80"), "#ff8800");
        compare(Fuzzy.color("rgb(255, 136, 0)"), "#ff8800");
        compare(Fuzzy.color("rgb(300, 0, 0)"), "");
        compare(Fuzzy.color("beaded"), "");
        compare(Fuzzy.color("ff8800"), "");
    }

    function test_keybinds() {
        const groups = [{ category: "Windows", rows: [{ description: "Close window", combos: [["Super", "W"], ["Alt", "F4"]] }] },
                        { category: "Apps", rows: [{ description: "Open files", combos: [["Super", "E"]] }] }];
        compare(Fuzzy.keybinds(groups, "close"), [{ description: "Close window", keys: "Super + W / Alt + F4", category: "Windows" }]);
        compare(Fuzzy.keybinds(groups, "super + e").map(k => k.description), ["Open files"]);
        compare(Fuzzy.keybinds(groups, "").length, 2);
        compare(Fuzzy.mode("? close"), { mode: "keys", text: "close" });
    }
}
