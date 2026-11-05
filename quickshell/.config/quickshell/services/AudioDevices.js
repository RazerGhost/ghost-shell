// Which sound devices take over when they're plugged in or connect (services/Audio.qml), like a
// phone: USB headphones and DACs (USB-C IEMs, a USB headset) for the sound and their microphone,
// Bluetooth headphones for the sound. Not a Bluetooth microphone: using it switches the headset
// into its call mode, which plays music in low quality, so calls pick it themselves. The jack
// needs nothing: it switches the laptop's own sound card between speakers and headphones.
// Plain JavaScript, tested (tests/tst_audiodevices.qml).
.pragma library

// Whether the PipeWire node `name` (an output when `sink`) should become the default when it
// appears.
function takesOver(name, sink) {
    const n = String(name ?? "");
    if (sink)
        return n.startsWith("alsa_output.usb-") || n.startsWith("bluez_output.");
    return n.startsWith("alsa_input.usb-");
}

// The names in `now` that weren't in `before` (lists of node names).
function added(before, now) {
    const known = new Set(Array.from(before ?? []));
    return Array.from(now ?? []).filter(name => !known.has(name));
}

// A short name for a sound device (the volume pop-up, the Sound page, the chooser under the
// volume slider), from its node name and PipeWire properties (an object; the node must be
// tracked for them to be there). The laptop's own card has long names ("Ryzen HD Audio
// Controller Speaker") but short profile names ("Speaker"); a USB device's profile name is only
// "Analog Stereo", its nickname the product ("SIMGOT EW300 DSP"); Bluetooth devices have their
// own short name as their description.
function label(name, props) {
    const n = String(name ?? "");
    const p = props ?? {};
    if (/^alsa_(output|input)\.pci-/.test(n))
        return p["device.profile.description"] || p["node.description"] || n;
    if (/^alsa_(output|input)\.usb-/.test(n))
        return p["node.nick"] || p["node.description"] || n;
    return p["node.description"] || p["node.nick"] || n;
}

// Whether an output is headphones (or a headset) for its icon: USB and Bluetooth audio nearly
// always is, and the laptop's card names its jack "Headphones".
function headphones(name, shownName) {
    const n = String(name ?? "");
    return n.startsWith("alsa_output.usb-") || n.startsWith("bluez_output.")
        || String(shownName ?? "").toLowerCase().includes("head");
}
