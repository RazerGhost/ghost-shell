import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/Presets.js" as Presets
import "../quickshell/.config/quickshell/settings/HyprlandConfig.js" as HyprlandConfig
import "../quickshell/.config/quickshell/theme/ThemeScale.js" as ThemeScale
import "../quickshell/.config/quickshell/desktop/DesktopWidgets.js" as DesktopWidgets

TestCase {
    name: "Presets"

    function test_current() {
        const tight = Object.assign({ other: 1 }, Presets.windows[1].values);
        compare(Presets.current(tight, Presets.windows), "Tight");
        // One value changed by hand: a look of your own.
        compare(Presets.current(Object.assign({}, tight, { gapsOut: 30 }), Presets.windows), "");
        compare(Presets.current(undefined, Presets.windows), "");
    }

    function test_apply() {
        const values = { windowAnimation: "popin", unrelated: true };
        Presets.apply(values, Presets.windows, "Playful");
        compare(values.windowAnimation, "gnomed");
        compare(values.wobble, true);
        verify(values.unrelated);
        compare(Presets.current(values, Presets.windows), "Playful");
        Presets.apply(values, Presets.windows, "Nope");
        compare(values.windowAnimation, "gnomed");
    }

    // Each editor's presets set only what that editor's Cancel puts back, with values its controls
    // offer, and no two are the same.
    function test_editorPresets() {
        const sets = [[Presets.desktop, Presets.desktopKeys],
                      [Presets.desktopWidgets, Presets.desktopKeys],
                      [Presets.dockIsland, Presets.dockIslandKeys], [Presets.windows, Presets.windowsKeys]];
        for (const [presets, keys] of sets) {
            for (const p of presets)
                for (const key of Object.keys(p.values))
                    verify(keys.includes(key), p.name + ": " + key);
            compare(new Set(presets.map(p => JSON.stringify(p.values))).size, presets.length);
        }
        for (const p of Presets.desktop) {
            verify(HyprlandConfig.blurStyles.includes(p.values.blurStyle), p.name);
            verify(ThemeScale.corners.includes(p.values.cornerScale), p.name);
        }
        for (const p of Presets.dockIsland) {
            verify(ThemeScale.dockIcons.includes(p.values.dockIconSize), p.name);
            verify(ThemeScale.workspaceDots.includes(p.values.workspaceDots), p.name);
        }
        for (const p of Presets.windows)
            verify(HyprlandConfig.animationSpeeds.includes(p.values.animationSpeed), p.name);
        // The first of each is how a fresh install looks.
        compare(Presets.current({ dockMode: "hide", dockIconSize: 44, workspaceDots: 5, hiddenStatusIcons: [],
                                  clockDate: false, clockSeconds: false, islandMedia: true }, Presets.dockIsland), "Ghost");
    }

    // Each widget layout's widgets on a 1920 x 1080 screen: on the screen, below the island and
    // above the dock, none over another; every widget that's on has a place, and only those.
    function test_widgetLayouts() {
        for (const preset of Presets.desktopWidgets) {
            const rects = [];
            for (const kind of DesktopWidgets.kinds) {
                const place = preset.values.desktopWidgets[kind.name];
                compare(preset.values[kind.key], place !== undefined, preset.name + " " + kind.name);
                if (!place)
                    continue;
                const r = { n: kind.name, x: place.x * 1920, y: place.y * 1080, w: DesktopWidgets.box(kind.name).w, h: DesktopWidgets.box(kind.name).h };
                // A hundredth of a pixel of slack: places are stored as rounded fractions.
                verify(r.x >= 31.99 && r.x + r.w <= 1920 - 31.99, preset.name + " " + r.n);
                verify(r.y >= 79.99 && r.y + r.h <= 1080 - 99.99, preset.name + " " + r.n);
                rects.push(r);
            }
            for (const a of rects)
                for (const b of rects)
                    if (a !== b)
                        verify(a.x + a.w <= b.x || b.x + b.w <= a.x || a.y + a.h <= b.y || b.y + b.h <= a.y,
                               preset.name + ": " + a.n + " over " + b.n);
        }
        // A fresh install (every widget off, none moved) is Clean.
        const fresh = { desktopWidgets: {} };
        for (const kind of DesktopWidgets.kinds)
            fresh[kind.key] = false;
        compare(Presets.current(fresh, Presets.desktopWidgets), "Clean");
    }

    // settings.json comes back with object keys sorted: still the same preset.
    function test_sameIgnoresKeyOrder() {
        verify(Presets.same({ clock: { x: 0.1, y: 0.2 }, battery: { y: 0.6, x: 0.5 } },
                            { battery: { x: 0.5, y: 0.6 }, clock: { y: 0.2, x: 0.1 } }));
        verify(Presets.same(undefined, null));
        verify(Presets.same(["a", "b"], ["a", "b"]));
        verify(!Presets.same(["a", "b"], ["b", "a"]));
        verify(!Presets.same({ a: 1 }, { a: 1, b: 2 }));
        verify(!Presets.same({ a: null }, { b: null }));
        verify(!Presets.same([], {}));
        verify(!Presets.same(0, null));
        // A list as settings.json gives it back: array-like, not an Array.
        verify(Presets.same({ length: 2, 0: "a", 1: "b" }, ["a", "b"]));
        const workday = Presets.desktopWidgets.find(p => p.name === "Workday").values;
        const reread = JSON.parse(JSON.stringify(workday));
        const sorted = {};
        for (const key of Object.keys(reread.desktopWidgets).sort())
            sorted[key] = reread.desktopWidgets[key];
        reread.desktopWidgets = sorted;
        compare(Presets.current(reread, Presets.desktopWidgets), "Workday");
    }

    function test_applyCopies() {
        const values = {};
        Presets.apply(values, Presets.dockIsland, "Minimal");
        values.hiddenStatusIcons.push("wifi");
        verify(!Presets.dockIsland[1].values.hiddenStatusIcons.includes("wifi"));
    }

    function test_presetsAreDistinct() {
        for (const presets of [Presets.desktop, Presets.desktopWidgets, Presets.dockIsland, Presets.windows])
            compare(new Set(presets.map(p => JSON.stringify(p.values))).size, presets.length);
    }

    function test_snapshotRestore() {
        const values = { rounding: 10, gapsOut: 20, other: 1 };
        const saved = Presets.snapshot(values, ["rounding", "gapsOut"]);
        Presets.apply(values, Presets.windows, "Spacious");
        values.gapsOut = 40;
        Presets.restore(values, saved);
        compare(values.rounding, 10);
        compare(values.gapsOut, 20);
        compare(values.other, 1);
    }

    // The layouts on other screens, and moved to a wallpaper's calmer side: on the screen, clear
    // of the island and dock, none over another; a one-sided layout moves; every widget is used.
    function test_widgetLayoutsAnywhere() {
        const used = new Set();
        for (const [sw, sh] of [[1920, 1080], [2560, 1440], [1366, 768], [3840, 2160]]) {
            for (const quiet of ["", "left", "right"]) {
            for (const cell of [0, 32, 48]) {
                const presets = Presets.widgetPresets(sw, sh, quiet, cell);
                verify(presets.length >= 3, sw + "x" + sh);
                for (const preset of presets) {
                    const rects = [];
                    for (const kind of DesktopWidgets.kinds) {
                        const place = preset.values.desktopWidgets[kind.name];
                        if (!place)
                            continue;
                        used.add(kind.name);
                        const b = DesktopWidgets.box(kind.name);
                        const r = { n: kind.name, x: place.x * sw, y: place.y * sh, w: b.w, h: b.h };
                        verify(r.x >= 31 && r.x + r.w <= sw - 31 && r.y >= 79 && r.y + r.h <= sh - 99, preset.name + " " + r.n + " " + sw);
                        rects.push(r);
                    }
                    for (const a of rects)
                        for (const b of rects)
                            if (a !== b)
                                verify(a.x + a.w <= b.x || b.x + b.w <= a.x || a.y + a.h <= b.y || b.y + b.h <= a.y,
                                       preset.name + ": " + a.n + " over " + b.n);
                }
            }
            }
        }
        compare(used.size, DesktopWidgets.kinds.length);
        // Planner sits on the right; on a picture calmer on the left it moves there; Everything
        // (both sides) stays.
        const x = (quiet, name, widget) => Presets.widgetPresets(1920, 1080, quiet).find(p => p.name === name).values.desktopWidgets[widget].x;
        verify(x("", "Planner", "clock") > 0.5);
        verify(x("left", "Planner", "clock") < 0.5);
        compare(x("right", "Planner", "clock"), x("", "Planner", "clock"));
        compare(x("left", "Everything", "clock"), x("", "Everything", "clock"));
    }

    // With the grid on, a preset's outer edges are on grid lines and mirrored layouts mirror.
    function test_widgetLayoutsOnGrid() {
        for (const [sw, sh] of [[1920, 1080], [2560, 1440]]) {
            for (const cell of [32, 48]) {
                const xs = DesktopWidgets.gridLines(sw, cell), ys = DesktopWidgets.gridLines(sh, cell);
                const on = (lines, v) => lines.some(l => Math.abs(l - v) < 0.01);
                const at = (quiet, name, w) => {
                    const p = Presets.widgetPresets(sw, sh, quiet, cell).find(p => p.name === name).values.desktopWidgets[w];
                    return { x: p.x * sw, y: p.y * sh, b: DesktopWidgets.box(w) };
                };
                // Glance, top left: the clock's left and top edges on lines.
                const g = at("", "Glance", "clock");
                verify(on(xs, g.x) && on(ys, g.y), "Glance " + sw + " " + cell);
                // Planner, in the middle of the height on the right: its tasks' right edge on a line,
                // the group centered on the middle line (clock on top, month and tasks below).
                const t = at("", "Planner", "tasks"), c = at("", "Planner", "clock");
                verify(on(xs, t.x + t.b.w), "Planner right " + sw);
                fuzzyCompare((c.y + t.y + t.b.h) / 2, sh / 2, 0.02);
                // Mirrored: Side on the left, and moved to the right for a picture calmer there.
                const l = at("", "Side", "clock"), r = at("right", "Side", "clock");
                fuzzyCompare(l.x, sw - (r.x + r.b.w), 0.02);
                // Everything: its two top blocks mirror (the left one's left edge, the right one's
                // right edge, the same distance from the screen's edges).
                const e1 = at("", "Everything", "clock"), e2 = at("", "Everything", "tasks");
                fuzzyCompare(e1.x, sw - (e2.x + e2.b.w), 0.02);
                verify(on(ys, e1.y) && on(ys, e2.y));
            }
        }
    }

    // Layouts per screen: applied on one screen, the widgets on another stay.
    function test_forScreen() {
        const base = Presets.widgetPresets(2560, 1440, "", 48);
        const values = { desktopClock: true, desktopWeather: true, desktopNote: true,
                         desktopWidgets: { clock: { x: 0.1, y: 0.1, screen: "DP-2" }, weather: { x: 0.2, y: 0.2 }, note: { x: 0.5, y: 0.5 } } };
        const screens = ["eDP-1", "DP-2"];
        // On DP-2: Glance (clock and weather) there; the note on the laptop stays on and put.
        const onDp2 = Presets.forScreen(base, values, "DP-2", "eDP-1", screens).find(p => p.name === "Glance").values;
        compare(onDp2.desktopClock, true);
        compare(onDp2.desktopWeather, true);
        compare(onDp2.desktopWidgets.weather.screen, "DP-2");   // moved over from the laptop
        compare(onDp2.desktopNote, true);
        compare(onDp2.desktopWidgets.note, { x: 0.5, y: 0.5 });
        // Clean on the laptop: its widgets off, DP-2's clock still on.
        const clean = Presets.forScreen(base, values, "eDP-1", "eDP-1", screens).find(p => p.name === "Clean").values;
        compare(clean.desktopClock, true);
        compare(clean.desktopWeather, false);
        compare(clean.desktopNote, false);
        // The main screen's layout widgets carry no screen (they follow a new main one).
        const glance = Presets.forScreen(base, values, "eDP-1", "eDP-1", screens).find(p => p.name === "Glance").values;
        compare(glance.desktopWidgets.weather.screen, undefined);
        compare(glance.desktopWidgets.clock.screen, undefined);
        // Applied, a layout matches itself (the gallery marks it).
        const applied = JSON.parse(JSON.stringify(values));
        const list = Presets.forScreen(base, values, "DP-2", "eDP-1", screens);
        Presets.apply(applied, list, "Glance");
        compare(Presets.current(applied, Presets.forScreen(base, applied, "DP-2", "eDP-1", screens)), "Glance");
    }

    // Saved layouts per screen: kept as one screen's widgets, applied on any screen.
    function test_savedLayoutPerScreen() {
        const screens = ["eDP-1", "DP-2"];
        const values = { desktopClock: true, desktopWeather: true, desktopNote: false,
                         desktopWidgets: { clock: { x: 0.1, y: 0.1, screen: "DP-2" }, weather: { x: 0.2, y: 0.2 }, note: { x: 0.5, y: 0.5 } } };
        // Saved on DP-2: only its clock, without the screen.
        const look = Presets.screenLayout(values, "DP-2", "eDP-1", screens);
        compare(look.desktopClock, true);
        compare(look.desktopWeather, false);
        compare(look.desktopWidgets, { clock: { x: 0.1, y: 0.1 } });
        // Applied on the laptop: the clock moves there, the weather (on the laptop, not in it) goes off.
        const onLaptop = Presets.forScreen([{ name: "Mine", values: look }], values, "eDP-1", "eDP-1", screens)[0].values;
        compare(onLaptop.desktopClock, true);
        compare(onLaptop.desktopWidgets.clock, { x: 0.1, y: 0.1 });
        compare(onLaptop.desktopWeather, false);
        // A saved layout from before (every widget's place, off ones too): only the ones on count.
        const old = { desktopClock: true, desktopNote: false, desktopWidgets: { clock: { x: 0.3, y: 0.3, screen: "DP-2" }, note: { x: 0.6, y: 0.6 } } };
        const fromOld = Presets.forScreen([{ name: "Old", values: old }], values, "eDP-1", "eDP-1", screens)[0].values;
        compare(fromOld.desktopNote, false);
        compare(fromOld.desktopWidgets.clock, { x: 0.3, y: 0.3 });
    }
}
