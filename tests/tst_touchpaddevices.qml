import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/TouchpadDevices.js" as TouchpadDevices

TestCase {
    name: "TouchpadDevices"

    function test_classify() {
        // The laptop on its own: the touchpad's two devices, no mouse.
        compare(TouchpadDevices.classify(["elan07c7:00-04f3:3298-mouse", "elan07c7:00-04f3:3298-touchpad"]),
                { touchpads: ["elan07c7:00-04f3:3298-touchpad"], mouse: false });
        // A Bluetooth mouse connected.
        compare(TouchpadDevices.classify(["elan07c7:00-04f3:3298-mouse", "elan07c7:00-04f3:3298-touchpad", "keychron-m6-mouse"]).mouse, true);
        // A desktop: a mouse, no touchpad.
        compare(TouchpadDevices.classify(["logitech-usb-receiver"]), { touchpads: [], mouse: true });
        compare(TouchpadDevices.classify([]), { touchpads: [], mouse: false });
    }
}
