import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/PowerModes.js" as PowerModes

TestCase {
    name: "PowerModes"

    // PowerProfile values: PowerSaver 0, Balanced 1, Performance 2.
    readonly property int saver: 0
    readonly property int balanced: 1
    readonly property int perf: 2

    function test_gameAlone() {
        compare(PowerModes.gameOn(balanced, { held: false, before: -1 }, perf), { before: balanced, profile: perf });
        compare(PowerModes.gameOff(perf, balanced, false, perf), { before: -1, profile: balanced });
        // Already in Performance: nothing to put back.
        compare(PowerModes.gameOn(perf, { held: false, before: -1 }, perf), { before: -1, profile: null });
        // Changed by hand meanwhile: left alone.
        compare(PowerModes.gameOff(saver, balanced, false, perf), { before: -1, profile: null });
    }

    function test_batteryAlone() {
        compare(PowerModes.lowBattery(balanced, { on: false, before: -1 }, saver), { before: balanced, profile: saver });
        compare(PowerModes.pluggedIn(balanced, false, perf), { before: -1, profile: balanced });
        compare(PowerModes.pluggedIn(-1, false, perf), { before: -1, profile: null });
    }

    // Balanced, game on, low battery, game off, plug in: Balanced (was stuck in Performance).
    function test_gameThenLowBattery() {
        const game = PowerModes.gameOn(balanced, { held: false, before: -1 }, perf);
        const low = PowerModes.lowBattery(game.profile, { on: true, before: game.before }, saver);
        compare(low, { before: balanced, profile: saver });
        compare(PowerModes.gameOff(low.profile, game.before, true, perf).profile, null); // the saver stays
        compare(PowerModes.pluggedIn(low.before, false, perf).profile, balanced);
    }

    // Low battery, game on, plug in, game off: Balanced (was left in power saver on AC).
    function test_lowBatteryThenGame() {
        const low = PowerModes.lowBattery(balanced, { on: false, before: -1 }, saver);
        const game = PowerModes.gameOn(low.profile, { held: true, before: low.before }, perf);
        compare(game, { before: balanced, profile: null }); // stays in power saver
        const plug = PowerModes.pluggedIn(low.before, true, perf);
        compare(plug.profile, perf); // game mode still on
        compare(PowerModes.gameOff(plug.profile, game.before, false, perf).profile, balanced);
    }
}
