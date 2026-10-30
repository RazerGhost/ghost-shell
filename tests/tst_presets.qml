import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/Presets.js" as Presets
import "../quickshell/.config/quickshell/settings/HyprlandConfig.js" as HyprlandConfig
import "../quickshell/.config/quickshell/theme/ThemeScale.js" as ThemeScale

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
