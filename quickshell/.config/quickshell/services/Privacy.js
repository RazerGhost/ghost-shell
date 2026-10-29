// Camera in use (services/Privacy.qml): its power state and the apps holding it, from
// services/camera.sh. Plain JavaScript, so it can be tested on its own (tests/tst_privacy.qml).
.pragma library

// The cameras' runtime_status values ("active", "suspended", ...): in use when any is active.
function inUse(states) {
    return states.some(s => s.trim() === "active");
}

// `camera.sh apps` ("app zoom\napp zoom\napp chromium\n") -> ["zoom", "chromium"].
function apps(text) {
    const names = text.split("\n").map(l => l.trim()).filter(l => l.startsWith("app ")).map(l => l.slice(4)).filter(a => a !== "");
    return [...new Set(names)];
}
