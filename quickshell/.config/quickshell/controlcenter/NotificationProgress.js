// A notification's progress bar, from the "value" hint apps send for long tasks (a download, a
// copy: `notify-send -h int:value:64 ...`). Plain JavaScript, so it can be tested on its own
// (tests/tst_notificationprogress.qml).
.pragma library

// 0-1, or -1 when the notification has no progress (no hint, or not a number).
function progress(hints) {
    const value = hints ? hints.value : undefined;
    if (typeof value !== "number" || !isFinite(value))
        return -1;
    return Math.min(100, Math.max(0, value)) / 100;
}
