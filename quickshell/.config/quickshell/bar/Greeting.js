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

// Your first name from your account's line in the user database (`getent passwd`: name, password,
// uid, gid, full name and more, then home and shell, separated by colons): the full name's first
// word, before any comma (some systems add a room or phone there); "" when there's none.
function firstName(passwdLine) {
    const full = (String(passwdLine ?? "").split(":")[4] ?? "").split(",")[0].trim();
    return full === "" ? "" : full.split(/\s+/)[0];
}
