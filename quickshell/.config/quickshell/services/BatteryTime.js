// "3h 20m" for the battery's time left or until full, and the battery's health and draw. Plain
// JavaScript, so it can be tested (tests/tst_battery.qml).
.pragma library

// Rounds to whole minutes first, so 7170 s is "2h 0m", not "1h 60m".
function duration(seconds) {
    const total = Math.round(seconds / 60);
    const hours = Math.floor(total / 60);
    const minutes = total % 60;
    return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
}

// The System page's battery line: "Health 86 % · Using 12.3 W" (charging: "Charging at"). `health`
// is 0-100 or -1 when the battery doesn't report it; `watts` 0 when nothing flows (plugged in
// and full) or unknown.
function details(health, watts, charging) {
    const parts = [];
    if (health >= 0)
        parts.push("Health " + Math.round(health) + " %");
    if (watts > 0)
        parts.push((charging ? "Charging at " : "Using ") + watts.toFixed(1) + " W");
    return parts.join(" · ");
}
