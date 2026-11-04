// The row the keys are on in a desktop widget's list (the to-do and clipboard widgets' keyboard
// mode): -1 for none. Plain JavaScript, so it can be tested on its own (tests/tst_listpick.qml).
.pragma library

// One step down (or up) from `pick` in a list of `length` rows: the new pick, or null past the
// ends (from none up, from the last down), where the arrow moves on to the next widget.
function step(pick, length, down) {
    const next = pick + (down ? 1 : -1);
    return next < -1 || next >= length ? null : next;
}

// The pick after the list changed (rows ticked off or removed elsewhere): still on the list.
function kept(pick, length) {
    return Math.min(pick, length - 1);
}
