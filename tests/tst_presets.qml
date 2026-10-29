import QtQuick
import QtTest
import "../quickshell/.config/quickshell/customize/Presets.js" as Presets

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
