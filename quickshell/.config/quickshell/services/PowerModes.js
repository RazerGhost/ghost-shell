// Who sets the power mode when game mode (services/GameMode.qml) and the low battery's power
// saver (services/BatteryAlerts.qml) both want to. Each used to keep the mode from before it and
// put it back blindly, so one undid the other: the laptop could stay in Performance on battery,
// or in power saver while plugged in. The rule: a low battery wins, and each puts back only what
// it set. Modes are PowerProfile values; `perf` is PowerProfile.Performance. Each function says
// what to remember (`before`, -1 for nothing) and what to switch to (`profile`, null to leave
// it). Plain JavaScript, tested (tests/tst_powermodes.qml).
.pragma library

// Game mode turned on. `saver`: { held: the low battery's power saver is on, before: the mode
// it will put back }. While the saver holds, game mode leaves the mode alone and remembers yours.
function gameOn(current, saver, perf) {
    if (saver.held)
        return { before: saver.before, profile: null };
    if (current === perf)
        return { before: -1, profile: null };
    return { before: current, profile: perf };
}

// Game mode turned off: your mode back, only if it's still in the Performance game mode set.
function gameOff(current, before, saverHeld, perf) {
    if (saverHeld || before === -1 || current !== perf)
        return { before: -1, profile: null };
    return { before: -1, profile: before };
}

// The low battery switches to power saver: it remembers your mode, the one from before game mode
// while game mode is on.
function lowBattery(current, game, saver) {
    return { before: game.on && game.before !== -1 ? game.before : current, profile: saver };
}

// Plugged in after the low battery's power saver: your mode back, or Performance while game mode
// is still on.
function pluggedIn(before, gameOn, perf) {
    if (before === -1)
        return { before: -1, profile: null };
    return { before: -1, profile: gameOn ? perf : before };
}
