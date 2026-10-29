// The OSD's keyboard pop-ups (osd/Osd.qml): the layout from Hyprland's activelayout event and
// caps lock from `hyprctl devices -j`. Plain JavaScript, so it can be tested on its own
// (tests/tst_osdkeyboard.qml).
.pragma library

// "at-translated-set-2-keyboard,English (US, intl., with dead keys)" -> the layout's name. Only
// the first comma separates: layout names have their own.
function layoutName(data) {
    const comma = data.indexOf(",");
    return comma === -1 ? "" : data.slice(comma + 1);
}

// Whether caps lock is on for the main keyboard (the one Hyprland marks "main"), from
// `hyprctl devices -j`; null when the output can't be read.
function capsLock(json) {
    try {
        const main = JSON.parse(json).keyboards.find(k => k.main);
        return main ? main.capsLock === true : null;
    } catch (e) {
        return null;
    }
}
