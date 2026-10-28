// Sound events (services/Sounds.qml): which freedesktop sound a notification plays, the sound
// file for a name, and USB plug events from `udevadm monitor`. Plain JavaScript, so it can be
// tested on its own (tests/tst_soundevents.qml).
.pragma library

const folder = "/usr/share/sounds/freedesktop/stereo/";

// The sound theme's file for a name ("message" -> .../message.oga), or "" for anything that
// isn't a plain sound name (names come from apps' notification hints).
function file(name) {
    return /^[a-z0-9-]+$/.test(name ?? "") ? folder + name + ".oga" : "";
}

// What a notification plays: nothing when the app asks for silence (the suppress-sound hint),
// the app's own choice of theme sound (sound-name), else the warning for a critical one and a
// soft chime for the rest.
function forNotification(hints, critical) {
    if (hints?.["suppress-sound"] === true)
        return "";
    if (file(hints?.["sound-name"]) !== "")
        return hints["sound-name"];
    return critical ? "dialog-warning" : "message";
}

// A line of `udevadm monitor --udev --subsystem-match=usb/usb_device`:
// "UDEV  [1234.5] add      /devices/pci0000:00/.../usb1/1-2 (usb)" -> "device-added",
// "... remove ..." -> "device-removed", anything else -> "".
function forUsbLine(line) {
    const match = line.match(/^UDEV\s+\[[\d.]+\]\s+(add|remove)\s+\S+\s+\(usb\)$/);
    return match ? (match[1] === "add" ? "device-added" : "device-removed") : "";
}
