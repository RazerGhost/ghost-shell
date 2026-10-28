// When a notification arrived, for its card. Plain JavaScript, so it can be tested on its own
// (tests/tst_notificationtime.qml).
.pragma library

// "now" under a minute, "5 min" under an hour, otherwise the time ("14:02"). Both arguments
// are milliseconds since the epoch.
function format(received, now) {
    const minutes = Math.floor((now - received) / 60000);
    if (minutes < 1)
        return "now";
    if (minutes < 60)
        return minutes + " min";
    const date = new Date(received);
    const pad = n => (n < 10 ? "0" : "") + n;
    return pad(date.getHours()) + ":" + pad(date.getMinutes());
}
