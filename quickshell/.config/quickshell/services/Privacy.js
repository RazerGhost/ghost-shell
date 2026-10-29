// Camera in use (services/Privacy.qml): parsing services/camera.sh. Plain JavaScript, so it can
// be tested on its own (tests/tst_privacy.qml).
.pragma library

// "in-use\napp zoom\napp zoom\n" -> { inUse: true, apps: ["zoom"] }; nothing -> not in use.
function camera(text) {
    const lines = text.split("\n").map(l => l.trim());
    const apps = lines.filter(l => l.startsWith("app ")).map(l => l.slice(4)).filter(a => a !== "");
    return { inUse: lines.includes("in-use"), apps: [...new Set(apps)] };
}
