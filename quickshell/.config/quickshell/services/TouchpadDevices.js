// Which pointer devices are touchpads, and whether a mouse is connected besides them, for
// services/Touchpad.qml. Plain JavaScript, so it can be tested on its own
// (tests/tst_touchpaddevices.qml).
.pragma library

// `mice`: Hyprland's pointer devices by name (`hyprctl devices -j`'s "mice"). A touchpad shows
// up twice ("<id>-touchpad" and "<id>-mouse", the same hardware); any other device is a mouse.
// Returns { touchpads: [names], mouse: bool }.
function classify(mice) {
    const touchpads = mice.filter(n => /touchpad/i.test(n));
    const ids = touchpads.map(n => n.replace(/-touchpad$/i, ""));
    const mouse = mice.some(n => !/touchpad/i.test(n) && !ids.some(id => n.startsWith(id)));
    return { touchpads: touchpads, mouse: mouse };
}
