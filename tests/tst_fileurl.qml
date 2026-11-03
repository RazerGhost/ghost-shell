import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/FileUrl.js" as FileUrl

TestCase {
    name: "FileUrl"

    function test_plain() {
        compare(FileUrl.of("/home/me/Pictures/art.png"), "file:///home/me/Pictures/art.png");
        compare(FileUrl.of(""), "");
        compare(FileUrl.of(undefined), "");
    }

    function test_special() {
        // # ? and % mean something in a URL; spaces and accents are encoded too.
        compare(FileUrl.of("/p/art #2?.png"), "file:///p/art%20%232%3F.png");
        compare(FileUrl.of("/p/100%.jpg"), "file:///p/100%25.jpg");
        compare(FileUrl.of("/p/café.jpg"), "file:///p/caf%C3%A9.jpg");
    }

    // Qt reads it back as the same file.
    function test_roundTrip() {
        const path = "/p/a #b/c?d%e.png";
        compare(new URL(FileUrl.of(path)).pathname, path);
    }
}
