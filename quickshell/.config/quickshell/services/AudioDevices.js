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

// The USB device a node belongs to ("usb-<id>"), so a headset's output and microphone are paired;
// "" for others.
function deviceOf(name) {
    const m = String(name ?? "").match(/^alsa_(?:output|input)\.(usb-.+)\.[^.]+$/);
    return m ? m[1] : "";
}

// What takes over among the nodes `added` (names) now that `all` are there: { sink, source }
// (names, or "" for none). An output as takesOver says; a USB microphone only with an output of
// the same device (a headset or DAC with a microphone, not a webcam or a microphone of its own:
// pick those in the Sound page, and WirePlumber brings them back by itself), and it comes along
// when that output takes over even if it appeared first. A node seen before in this session
// takes over again only if it was in use when it left (`left`: { name: wasDefault }), so waking
// from sleep (USB devices reconnect) doesn't undo a choice of the speakers.
function takeovers(added, all, left) {
    const names = Array.from(all ?? []);
    const back = name => left?.[name] === false;
    const outputs = Array.from(added ?? []).filter(n => takesOver(n, true) && !back(n));
    const sink = outputs[0] ?? "";
    const pairedInput = dev => dev !== "" ? names.find(n => n.startsWith("alsa_input.") && deviceOf(n) === dev) ?? "" : "";
    let source = sink !== "" ? pairedInput(deviceOf(sink)) : "";
    if (source === "") {
        source = Array.from(added ?? []).find(n => takesOver(n, false) && !back(n)
            && names.some(o => o.startsWith("alsa_output.") && deviceOf(o) === deviceOf(n))) ?? "";
    }
    if (source !== "" && back(source))
        source = "";
    return { sink: sink, source: source };
}
