import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Privacy.js" as Privacy

TestCase {
    name: "Privacy"

    function test_inUse() {
        verify(!Privacy.inUse([]));
        verify(!Privacy.inUse(["suspended\n"]));
        verify(Privacy.inUse(["suspended", "active\n"]));
    }

    function test_apps() {
        compare(Privacy.apps(""), []);
        compare(Privacy.apps("app zoom\napp zoom\napp chromium\napp \n"), ["zoom", "chromium"]);
    }
}
