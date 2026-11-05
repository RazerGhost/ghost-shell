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
