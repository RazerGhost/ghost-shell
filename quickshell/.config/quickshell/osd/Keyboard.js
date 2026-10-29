// The OSD's keyboard pop-ups (osd/Osd.qml): the layout from Hyprland's activelayout event and
// caps lock from `hyprctl devices -j`. Plain JavaScript, so it can be tested on its own
// (tests/tst_osdkeyboard.qml).
.pragma library

// "at-translated-set-2-keyboard,English (US, intl., with dead keys)" -> { keyboard, layout }.
// Only the first comma separates: layout names have their own. null for anything else.
function activeLayout(data) {
    const comma = data.indexOf(",");
    return comma === -1 ? null : { keyboard: data.slice(0, comma), layout: data.slice(comma + 1) };
}

// The main keyboard (the one Hyprland marks "main") from `hyprctl devices -j`, as
// { name, layout, capsLock }; null when the output can't be read.
function mainKeyboard(json) {
    try {
        const main = JSON.parse(json).keyboards.find(k => k.main);
        return main ? { name: main.name, layout: main.active_keymap, capsLock: main.capsLock === true } : null;
    } catch (e) {
        return null;
    }
}
