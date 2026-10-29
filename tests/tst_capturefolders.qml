import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/CaptureFolders.js" as CaptureFolders

TestCase {
    name: "CaptureFolders"

    readonly property string home: "/home/me"
    readonly property string fallback: "/home/me/Pictures/Screenshots"

    function test_folder() {
        compare(CaptureFolders.folder("", home, fallback), fallback);
        compare(CaptureFolders.folder("  ~/Shots/ ", home, fallback), "/home/me/Shots");
        compare(CaptureFolders.folder("~", home, fallback), "/home/me");
        compare(CaptureFolders.folder("/mnt/data/clips", home, fallback), "/mnt/data/clips");
        compare(CaptureFolders.folder("Shots", home, fallback), fallback);          // not absolute
        compare(CaptureFolders.folder("/tmp/a\nb", home, fallback), fallback);      // a line break
        compare(CaptureFolders.folder(undefined, home, fallback), fallback);
    }

    function test_short() {
        compare(CaptureFolders.short("/home/me/Pictures/Screenshots", home), "~/Pictures/Screenshots");
        compare(CaptureFolders.short("/home/me", home), "~");
        compare(CaptureFolders.short("/home/mexico", home), "/home/mexico");
        compare(CaptureFolders.short("/mnt/x", home), "/mnt/x");
    }
}
