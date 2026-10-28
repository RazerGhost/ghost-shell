// Track position and length for the media menu. Plain JavaScript, so it can be tested on its
// own (tests/tst_tracktime.qml).
.pragma library

// "3:07", or "1:02:03" past an hour. MPRIS gives positions and lengths in seconds.
function format(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    const pad = n => (n < 10 ? "0" : "") + n;
    const h = Math.floor(s / 3600);
    const m = Math.floor(s / 60) % 60;
    return h > 0 ? h + ":" + pad(m) + ":" + pad(s % 60) : m + ":" + pad(s % 60);
}
