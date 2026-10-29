// Per-app notification settings (Settings -> Notifications): each app that has sent a
// notification is remembered in `notificationApps` (settings.json) as { mode }. Plain
// JavaScript, so it can be tested on its own (tests/tst_notificationrules.qml).
.pragma library

// "silent": only into the list; "normal": pops up unless Do Not Disturb or game mode is on;
// "always": pops up through those too.
const modes = ["silent", "normal", "always"];
const labels = { silent: "Silent", normal: "Pop up", always: "Always pop up" };

function mode(apps, name) {
    const m = apps?.[name]?.mode;
    return modes.includes(m) ? m : "normal";
}

// Whether a new notification pops up (with its sound). Critical ones always do.
function popsUp(mode, quiet, critical) {
    if (critical || mode === "always")
        return true;
    return mode === "normal" && !quiet;
}

// The settings with a newly seen app added ("normal"), or null when it's already there (or has
// no name to show).
function remember(apps, name) {
    if (name === "" || (apps ?? {})[name] !== undefined)
        return null;
    return Object.assign({}, apps, { [name]: { mode: "normal" } });
}

// The settings with an app's mode changed.
function withMode(apps, name, mode) {
    return Object.assign({}, apps, { [name]: Object.assign({}, apps[name], { mode: mode }) });
}
