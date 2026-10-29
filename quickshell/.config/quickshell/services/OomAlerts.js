// Apps closed because memory ran out, for services/OomAlerts.qml. Plain JavaScript, so it can be
// tested on its own (tests/tst_oomalerts.qml).
.pragma library

// One journal entry (a line of `journalctl -o json`) -> { app, session, time } when it's a kill:
// the kernel's OOM killer ("Out of memory: Killed process 1234 (zen-bin) ...") or systemd-oomd's
// ("Killed /user.slice/.../pipewire.service due to ..."). `session` is true when oomd closed this
// user's whole login session (every app runs in it, Hyprland too). `time` is in microseconds.
function kill(line, uid) {
    let entry;
    try {
        entry = JSON.parse(line);
    } catch (e) {
        return null;
    }
    const message = entry.MESSAGE;
    if (typeof message !== "string")
        return null;
    const time = Number(entry.__REALTIME_TIMESTAMP) || 0;
    if (entry.SYSLOG_IDENTIFIER === "kernel") {
        const match = message.match(/Killed process \d+ \((.*?)\)/);
        return match ? { app: match[1], session: false, time: time } : null;
    }
    if (entry.SYSLOG_IDENTIFIER === "systemd-oomd") {
        const match = message.match(/^Killed (\/\S+)/);
        if (!match)
            return null;
        // Another user's session or apps aren't ours to report.
        if (match[1].startsWith("/user.slice/") && !match[1].includes("/user-" + uid + ".slice/"))
            return null;
        if (match[1].includes("/session-"))
            return { app: "", session: true, time: time };
        const unit = match[1].split("/").pop().replace(/\.(service|scope|slice)$/, "");
        // An app in its own scope: app-ghost-<desktop id>-<random> (services/Apps.qml) or
        // Chromium's app-<id>-<pid>; the id names the app.
        const scope = unit.match(/^app-(?:ghost-)?(.+)-[0-9a-f]+$/);
        return { app: scope ? scope[1] : unit, session: false, time: time };
    }
    return null;
}
