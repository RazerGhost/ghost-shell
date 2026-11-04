// What the island says after an unlock (bar/WelcomeCard.qml). Plain JavaScript, so it can be
// tested on its own (tests/tst_greeting.qml).
.pragma library

// The first unlock of a session (the login) greets by the time of day; later ones welcome you
// back. `hour` 0-23; `name` may be "".
function greeting(hour, name, first) {
    const to = name ? ", " + name : "";
    if (!first)
        return "Welcome back" + to;
    const part = hour >= 5 && hour < 12 ? "morning" : hour >= 12 && hour < 18 ? "afternoon" : "evening";
    return "Good " + part + to;
}

// "3 notifications", "1 notification".
function count(n, one, many) {
    return n + " " + (n === 1 ? one : many);
}
