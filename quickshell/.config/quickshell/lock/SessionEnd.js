// What the logging out / restarting / shutting down screen says (lock/SessionEnd.qml). Plain
// JavaScript, so it can be tested on its own (tests/tst_sessionend.qml).
.pragma library

// The line under the title. `started`: how many windows there were to close (it grows when an
// app answers with a new window, a "save?" dialog, so the count never goes below zero);
// `remaining`: how many are still open; `stuck`: waited long enough with some still open.
function message(started, remaining, stuck) {
    if (stuck)
        return remaining === 1 ? "This app hasn't closed. It may be asking you something."
                               : "These apps haven't closed. They may be asking you something.";
    if (remaining > 0)
        return "Closing your apps… " + Math.max(started - remaining, 0) + " of " + Math.max(started, remaining);
    return started > 0 ? "Your apps are closed" : "";
}
