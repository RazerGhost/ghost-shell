// Where screenshots and recordings go (Settings -> Screenshots and recordings). Plain JavaScript,
// so it can be tested on its own (tests/tst_capturefolders.qml).
.pragma library

// The folder for a setting: "" is the default; "~" or "~/..." is in the home folder; anything
// that isn't an absolute path (or has a line break) falls back to the default.
function folder(setting, home, fallback) {
    let path = (setting ?? "").trim();
    if (path === "")
        return fallback;
    if (path === "~" || path.startsWith("~/"))
        path = home + path.slice(1);
    if (!path.startsWith("/") || /[\n\r]/.test(path))
        return fallback;
    return path.replace(/\/+$/, "") || "/";
}

// "/home/me/Pictures/Screenshots" -> "~/Pictures/Screenshots", for notifications and Settings.
function short(path, home) {
    return path === home ? "~" : path.startsWith(home + "/") ? "~" + path.slice(home.length) : path;
}
