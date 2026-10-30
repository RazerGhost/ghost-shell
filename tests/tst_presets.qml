import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/Presets.js" as Presets
import "../quickshell/.config/quickshell/settings/HyprlandConfig.js" as HyprlandConfig
import "../quickshell/.config/quickshell/theme/ThemeScale.js" as ThemeScale
import "../quickshell/.config/quickshell/desktop/DesktopWidgets.js" as DesktopWidgets
import "../quickshell/.config/quickshell/lock/LockWidgets.js" as LockWidgets

TestCase {
    name: "Presets"

    function test_current() {
        const classic = Object.assign({ other: 1 }, Presets.lock[0].values);
        compare(Presets.current(classic, Presets.lock), "Classic");
        // One value changed by hand: a look of your own.
        compare(Presets.current(Object.assign({}, classic, { lockDim: 30 }), Presets.lock), "");
        compare(Presets.current(undefined, Presets.lock), "");
    }

    function test_apply() {
        const values = { lockClockStyle: "big", unrelated: true };
        Presets.apply(values, Presets.lock, "Analog");
        compare(values.lockClockStyle, "analog");
        compare(values.lockLayout, "left");
        verify(values.unrelated);
        compare(Presets.current(values, Presets.lock), "Analog");
        Presets.apply(values, Presets.lock, "Nope");
        compare(values.lockClockStyle, "analog");
    }

    // Each editor's presets set only what that editor's Cancel puts back, with values its controls
    // offer, and no two are the same.
    function test_editorPresets() {
        const sets = [[Presets.lock, Presets.lockKeys], [Presets.desktop, Presets.desktopKeys],
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
                const r = { n: kind.name, x: place.x * 1920, y: place.y * 1080, w: kind.medium ? 352 : 168, h: 168 };
                verify(r.x >= 32 && r.x + r.w <= 1920 - 32, preset.name + " " + r.n);
                verify(r.y >= 80 && r.y + r.h <= 1080 - 100, preset.name + " " + r.n);
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

    // The lock looks' widgets: known ones, at most the row's limit, never the next event (its
    // title would show to anyone at the screen).
    function test_lockLooksWidgets() {
        for (const preset of Presets.lock) {
            const list = preset.values.lockWidgets;
            compare(LockWidgets.shown(list, {}), list, preset.name);
            verify(!list.includes("event"), preset.name);
        }
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
        const seen = Presets.lock.map(p => JSON.stringify(p.values));
        compare(new Set(seen).size, Presets.lock.length);
    }

    function test_snapshotRestore() {
        const values = { lockClockStyle: "big", lockBlur: 100, other: 1 };
        const saved = Presets.snapshot(values, ["lockClockStyle", "lockBlur"]);
        Presets.apply(values, Presets.lock, "Analog");
        values.lockBlur = 10;
        Presets.restore(values, saved);
        compare(values.lockClockStyle, "big");
        compare(values.lockBlur, 100);
        compare(values.other, 1);
        // Every key a lock preset sets is one Cancel puts back.
        for (const p of Presets.lock)
            for (const key of Object.keys(p.values))
                verify(Presets.lockKeys.includes(key), key);
    }
}
