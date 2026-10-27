// Which workspace dots the island shows, and where scrolling goes. Plain JavaScript, so it
// can be tested on its own (tests/tst_workspaces.qml).
.pragma library

// Ids 1..n: always at least `minimum` dots, more when a higher workspace exists, so a
// workspace you opened with Super+8 still gets a dot.
function slots(minimum, existingIds) {
    const n = Math.max(minimum, ...existingIds.filter(id => id > 0));
    return Array.from({ length: n }, (_, i) => i + 1);
}

// The workspace one step (delta = +1 or -1) away from `active`, wrapping around at the
// ends of the dots.
function step(active, delta, count) {
    return ((active - 1 + delta) % count + count) % count + 1;
}
