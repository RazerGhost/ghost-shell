import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/MediaAccent.js" as MediaAccent

TestCase {
    name: "MediaAccent"

    function test_accent() {
        // A dark red cover with a grey background: the red, lightened for the dark menu.
        compare(MediaAccent.accent([{ h: -1, s: 0, l: 0.5 }, { h: 0.0, s: 0.8, l: 0.3 }]), { h: 0.0, s: 0.8, l: 0.7 });
        // The most colorful wins.
        compare(MediaAccent.accent([{ h: 0.6, s: 0.3, l: 0.5 }, { h: 0.3, s: 0.9, l: 0.75 }]).h, 0.3);
        // Black and white, or grey: none (the theme's accent stays).
        compare(MediaAccent.accent([{ h: -1, s: 0, l: 0 }, { h: 0.1, s: 0.05, l: 0.5 }, { h: 0.5, s: 0.5, l: 0.98 }]), null);
        compare(MediaAccent.accent([]), null);
    }
}
