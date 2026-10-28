import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/SoundEvents.js" as SoundEvents

TestCase {
    name: "SoundEvents"

    function test_file() {
        compare(SoundEvents.file("message"), "/usr/share/sounds/freedesktop/stereo/message.oga");
        // Names come from apps: nothing that could leave the folder.
        compare(SoundEvents.file("../../etc/x"), "");
        compare(SoundEvents.file(""), "");
        compare(SoundEvents.file(undefined), "");
    }

    function test_forNotification() {
        compare(SoundEvents.forNotification({}, false), "message");
        compare(SoundEvents.forNotification({}, true), "dialog-warning");
        compare(SoundEvents.forNotification({ "sound-name": "bell" }, false), "bell");
        compare(SoundEvents.forNotification({ "sound-name": "/tmp/x.wav" }, false), "message");
        compare(SoundEvents.forNotification({ "suppress-sound": true, "sound-name": "bell" }, true), "");
        compare(SoundEvents.forNotification(undefined, false), "message");
    }

    function test_forUsbLine() {
        compare(SoundEvents.forUsbLine("UDEV  [12345.678901] add      /devices/pci0000:00/0000:00:08.1/0000:05:00.3/usb1/1-2 (usb)"), "device-added");
        compare(SoundEvents.forUsbLine("UDEV  [12346.1] remove   /devices/pci0000:00/0000:00:08.1/0000:05:00.3/usb1/1-2 (usb)"), "device-removed");
        compare(SoundEvents.forUsbLine("UDEV  [12346.1] bind     /devices/pci0000:00/usb1/1-2 (usb)"), "");
        compare(SoundEvents.forUsbLine("monitor will print the received events for:"), "");
    }
}
