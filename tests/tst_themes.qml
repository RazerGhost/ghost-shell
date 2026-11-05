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
        // Nothing of its own left: dropped (it would match any look).
        compare(Themes.valid([{ name: "A", wallpaper: "/a.png", values: { uiScale: 120 } }]), []);
    }

    function test_applicable() {
        const current = { glassOpacity: 45, glass: true, desktopWidgets: {}, fontSans: "" };
        compare(Themes.applicable({ glassOpacity: "x", glass: false, desktopWidgets: 5, fontSans: "Inter" }, current),
                { glass: false, fontSans: "Inter" });
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

    function test_renamed() {
        const themes = [{ name: "Theme 1", values: {} }, { name: "Theme 2", values: {} }];
        compare(Themes.renamed(themes, "Theme 1", "  Evening ").map(t => t.name), ["Evening", "Theme 2"]);
        // Empty or taken: unchanged.
        compare(Themes.renamed(themes, "Theme 1", " ").map(t => t.name), ["Theme 1", "Theme 2"]);
        compare(Themes.renamed(themes, "Theme 1", "Theme 2").map(t => t.name), ["Theme 1", "Theme 2"]);
    }

    // Per screen: a theme keeps one screen's widgets and applies them on the editor's screen.
    function test_onScreen() {
        const screens = ["eDP-1", "DP-2"];
        const values = { glass: true, desktopClock: true, desktopWeather: true,
                         desktopWidgets: { clock: { x: 0.1, y: 0.1, screen: "DP-2" }, weather: { x: 0.2, y: 0.2 } } };
        const saved = Themes.screenValues(values, "eDP-1", "eDP-1", screens);
        compare(saved.desktopWeather, true);
        compare(saved.desktopClock, false);   // on DP-2: not this screen's
        compare(saved.glass, true);
        const theme = { name: "T", wallpaper: "", values: saved };
        // Applied on DP-2: the weather goes there, DP-2's clock (not in it) off, the laptop untouched.
        const there = Themes.onScreen(theme, values, "DP-2", "eDP-1", screens).values;
        compare(there.desktopWidgets.weather.screen, "DP-2");
        compare(there.desktopClock, false);
        compare(there.glass, true);
    }
}
