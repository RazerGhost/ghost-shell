import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Privacy.js" as Privacy

TestCase {
    name: "Privacy"

    function test_camera() {
        compare(Privacy.camera(""), { inUse: false, apps: [] });
        compare(Privacy.camera("in-use\n"), { inUse: true, apps: [] });
        compare(Privacy.camera("in-use\napp zoom\napp zoom\napp chromium\napp \n"), { inUse: true, apps: ["zoom", "chromium"] });
    }
}
