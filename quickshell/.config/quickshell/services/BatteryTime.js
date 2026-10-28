// "3h 20m" for the battery's time left or until full. Plain JavaScript, so it can be tested
// (tests/tst_battery.qml).
.pragma library

// Rounds to whole minutes first, so 7170 s is "2h 0m", not "1h 60m".
function duration(seconds) {
    const total = Math.round(seconds / 60);
    const hours = Math.floor(total / 60);
    const minutes = total % 60;
    return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
}
