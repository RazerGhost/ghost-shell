import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/Themes.js" as Themes

TestCase {
    name: "Themes"

    function test_valid() {
        compare(Themes.valid(undefined), []);
        compare(Themes.valid([{ name: "" , wallpaper: "", values: {} }, { name: "A", values: {} }, "x"]), []);
        // Unknown keys dropped; the card's color kept when it's text.
        compare(Themes.valid([{ name: "A", wallpaper: "/a.png", primary: 3, values: { glass: true, uiScale: 120 } }]),
                [{ name: "A", wallpaper: "/a.png", primary: "", values: { glass: true } }]);
    }

    function test_made() {
        const values = { glass: true, desktopWidgets: { clock: { x: 0.1, y: 0.2 } }, uiScale: 110 };
        const theme = Themes.made([{ name: "Theme 1" }], values, "/a.png", "#ffaa00");
        compare(theme.name, "Theme 2");
        compare(theme.wallpaper, "/a.png");
        compare(theme.values.glass, true);
        verify(!("uiScale" in theme.values));
        // A copy: moving a widget later doesn't change the theme.
        values.desktopWidgets.clock.x = 0.5;
        compare(theme.values.desktopWidgets.clock.x, 0.1);
    }

    function test_current() {
        const values = { glass: true, desktopWidgets: { clock: { x: 0.1, y: 0.2 } } };
        const theme = Themes.made([], values, "/a.png", "");
        compare(Themes.current([theme], values, "/a.png"), "Theme 1");
        // Another wallpaper, or a setting changed since: not that theme.
        compare(Themes.current([theme], values, "/b.png"), "");
        compare(Themes.current([theme], Object.assign({}, values, { glass: false }), "/a.png"), "");
        compare(Themes.removed([theme], "Theme 1"), []);
    }
}
