import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/LooksFile.js" as LooksFile

TestCase {
    name: "LooksFile"

    function test_paths() {
        compare(LooksFile.path("/home/a/Pictures/x.png", "/home/a", false), "~/Pictures/x.png");
        compare(LooksFile.path("/home/ab/x.png", "/home/a", false), "/home/ab/x.png");
        compare(LooksFile.path("/usr/share/x.png", "/home/a", false), "/usr/share/x.png");
        compare(LooksFile.path("~/Pictures/x.png", "/home/b", true), "/home/b/Pictures/x.png");
        compare(LooksFile.path("", "/home/b", true), "");
    }

    function test_exported() {
        const settings = { themes: [{ name: "Night", wallpaper: "/home/a/w.png", values: { glass: true } }],
                           lockLooks: [{ name: "Mine", values: { lockWallpaper: "/home/a/l.png", lockBlur: 10 } }],
                           dockLooks: "broken" };
        const file = LooksFile.exported(settings, "/home/a");
        compare(file.themes[0].wallpaper, "~/w.png");
        compare(file.lockLooks[0].values.lockWallpaper, "~/l.png");
        compare(file.dockLooks, []);
        compare(file.windowLooks, []);
        // The settings themselves aren't changed.
        compare(settings.themes[0].wallpaper, "/home/a/w.png");
    }

    function test_imported() {
        const here = { themes: [{ name: "Night", wallpaper: "/home/b/old.png", values: {} },
                                { name: "Only here", wallpaper: "", values: {} }] };
        const file = { themes: [{ name: "Night", wallpaper: "~/new.png", values: { glass: false } },
                                { name: "New", wallpaper: "", values: {} }, { name: "" }] };
        const merged = LooksFile.imported(here, file, "/home/b");
        // Same name replaced (in its place), new ones after, mine kept, nameless dropped.
        compare(merged.themes.map(t => t.name), ["Night", "Only here", "New"]);
        compare(merged.themes[0].wallpaper, "/home/b/new.png");
        compare(merged.lockLooks, []);
    }
}
