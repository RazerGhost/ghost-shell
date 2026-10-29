// The keyboard service (services/Keyboard.qml): Hyprland's activelayout event and the main keyboard
// from `hyprctl devices -j`. Plain JavaScript, so it can be tested on its own
// (tests/tst_keyboarddevices.qml).
.pragma library

// "at-translated-set-2-keyboard,English (US, intl., with dead keys)" -> { keyboard, layout }.
// Only the first comma separates: layout names have their own. null for anything else.
function activeLayout(data) {
    const comma = data.indexOf(",");
    return comma === -1 ? null : { keyboard: data.slice(0, comma), layout: data.slice(comma + 1) };
}

// The main keyboard (the one Hyprland marks "main") from `hyprctl devices -j`, as
// { name, layout, layouts }: the active layout's name and how many it switches between
// ("us,nl" is 2). null when the output can't be read.
function mainKeyboard(json) {
    try {
        const main = JSON.parse(json).keyboards.find(k => k.main);
        return main ? { name: main.name, layout: main.active_keymap, layouts: String(main.layout ?? "").split(",").length } : null;
    } catch (e) {
        return null;
    }
}
