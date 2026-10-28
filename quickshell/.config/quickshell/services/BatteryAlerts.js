// When to warn about the battery, for services/BatteryAlerts.qml. Plain JavaScript, so it can be
// tested on its own (tests/tst_batteryalerts.qml).
.pragma library

// The warning to give now: "critical", "low" or "" (none). `level` is 0-1; `given` is the most
// serious warning already given since the last charge ("", "low" or "critical"), so each is
// given once per discharge.
function warning(level, charging, given, lowAt, criticalAt) {
    if (charging)
        return "";
    if (level <= criticalAt && given !== "critical")
        return "critical";
    if (level <= lowAt && given === "")
        return "low";
    return "";
}
