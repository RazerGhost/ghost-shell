import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Wallpapers.js" as Wallpapers

TestCase {
    name: "Wallpapers"

    function test_entries() {
        const text = [
            "/home/me/Pictures/Wallpapers/forest.jpg",
            "/usr/share/hypr/wall0.png",
            "/usr/share/wallpapers/Flow/contents/images/1280x800.png",
            "/usr/share/wallpapers/Flow/contents/images/1920x1080.png",
            "/usr/share/wallpapers/Flow/contents/images/3840x2160.png",
            "/usr/share/wallpapers/Flow/contents/images_dark/1920x1080.png",
            "/usr/share/wallpapers/Flow/contents/screenshot.png",
            "/usr/share/wallpapers/Next/contents/images/2560x1440.jpg",
            "/usr/share/wallpapers/Next/contents/images/5120x2880.jpg",
            "/usr/share/backgrounds/gnome/blobs-l.jxl",
            "/usr/share/backgrounds/gnome/blobs-d.jxl",
            "/usr/share/backgrounds/city_dark.png",
            "/usr/share/backgrounds/nwg-shell/nwg-hole.jpg",
            ""
        ].join("\n");
        const list = Wallpapers.entries(text, 1920, 1080, "/home/me/Pictures/Wallpapers");
        compare(list.map(e => e.fileName), ["forest.jpg", "wall0.png", "Flow", "Next", "blobs-l.jxl", "city_dark.png", "nwg-hole.jpg"]);
        verify(list[0].own);
        verify(!list[1].own);
        // Plasma: the screen's size, its dark version paired.
        compare(list[2].filePath, "/usr/share/wallpapers/Flow/contents/images/1920x1080.png");
        compare(list[2].darkPath, "/usr/share/wallpapers/Flow/contents/images_dark/1920x1080.png");
        // No exact size: the smallest that covers the screen.
        compare(list[3].filePath, "/usr/share/wallpapers/Next/contents/images/2560x1440.jpg");
        compare(list[3].darkPath, "");
        // GNOME's -l / -d pair.
        compare(list[4].filePath, "/usr/share/backgrounds/gnome/blobs-l.jxl");
        compare(list[4].darkPath, "/usr/share/backgrounds/gnome/blobs-d.jxl");
        // A dark one alone is just a picture.
        compare(list[5].filePath, "/usr/share/backgrounds/city_dark.png");
        compare(list[5].darkPath, "");
    }

    function test_bestSize() {
        const sizes = [{ path: "a", w: 1600, h: 900 }, { path: "b", w: 1280, h: 800 }];
        compare(Wallpapers.bestSize(sizes, 1920, 1080), "a"); // none covers: the biggest
    }

    function test_videos() {
        const text = "/home/me/W/rain.mp4\t/home/me/.cache/quickshell/wallpaper-thumbs/ab.jpg\n/home/me/W/rain-dark.mp4\t\n/home/me/W/sea.jpg\n";
        const list = Wallpapers.entries(text, 1920, 1080, "/home/me/W");
        compare(list.length, 3); // videos are never paired
        verify(list[0].video);
        compare(list[0].thumb, "/home/me/.cache/quickshell/wallpaper-thumbs/ab.jpg");
        compare(list[1].thumb, "");
        verify(!list[2].video);
        compare(list[2].thumb, "");
    }
}
