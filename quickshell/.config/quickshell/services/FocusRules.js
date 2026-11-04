// Focus mode's rules (services/Focus.qml): which timer it owns, when starting it starts a timer,
// when stopping it cancels one. Plain JavaScript, so it can be tested on its own
// (tests/tst_focusrules.qml). `focus` is { on, timer, breakTimer } (timer and breakTimer:
// Countdown.runs of the session's and the break's timers, -1 for none); `countdown` is
// { active, runs }.
.pragma library

// The running timer is a break focus mode started.
function onBreak(focus, countdown) {
    return countdown.active && focus.breakTimer === countdown.runs;
}

// The timer that ran out (its `runs`) is the session's or the break's: Focus announces its end
// instead of Countdown's own "Time's up".
function owns(focus, runs) {
    return (focus.on && focus.timer === runs) || focus.breakTimer === runs;
}

// Starting a session: "ignore" while one runs (an old "Focus again" from the history), "run" a
// timer of its own when none runs or a break does (the session replaces it), else "use" the
// timer that's running.
function start(focus, countdown) {
    if (focus.on)
        return "ignore";
    return !countdown.active || onBreak(focus, countdown) ? "run" : "use";
}

// Stopping cancels the timer only if it's still the session's own: not one that was running
// before, or one started over it since.
function stopCancels(focus, countdown) {
    return countdown.active && countdown.runs === focus.timer;
}
