// The wallpaper: a picture drawn by wallpaper/WallpaperLayer.qml. Choosing one also runs matugen
// on it, which recolors the shell, Hyprland, Ghostty, GTK and the other apps from the picture.
// Settings -> Appearance: your folder, a slideshow, and following light and dark (a picture with
// a dark version switches to it in dark mode and back).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "CaptureFolders.js" as CaptureFolders
import "Wallpapers.js" as WallpapersJs

Singleton {
    id: root

    // Your folder (Settings' wallpaperFolder; ~/Pictures/Wallpapers by default).
    readonly property string folder: CaptureFolders.folder(Settings.values.wallpaperFolder, Quickshell.env("HOME"),
                                                           Quickshell.env("HOME") + "/Pictures/Wallpapers")
    // The current wallpaper's path; "" until one is chosen (Hyprland's default shows then).
    readonly property string path: state.path
    // A live wallpaper (a video), and the still picture for it: a frame that matugen's
    // wallpaper.sh made (the colors come from it; the lock and login screens show it).
    readonly property bool isVideo: WallpapersJs.isVideo(path)
    readonly property string stillPath: isVideo ? Quickshell.env("HOME") + "/.local/state/quickshell/video-frame.jpg" : path
    // The lock and login screens' picture: the one chosen in settings, or else the desktop's.
    readonly property string lockPath: Settings.values.lockWallpaper || stillPath
    // The picker strip is open (wallpaper/WallpaperPicker.qml): quick settings' button, or
    // `qs ipc call wallpaper picker`.
    property bool pickerOpen: false

    // Every picture to choose from, as { filePath, fileName, darkPath, own }: yours first, then
    // Hyprland's and the installed collections (CachyOS, KDE Plasma, nwg-shell, Ubuntu's art
    // contest; from their packages, not copied anywhere). Found by services/wallpapers.sh and
    // grouped by Wallpapers.js (tested): a Plasma picture at your screen's size, dark versions
    // paired with their light ones.
    property var pictures: []
    readonly property int ownCount: pictures.filter(p => p.own).length

    // Look again (pickers call this when they open): new pictures, a new folder.
    function rescan(): void {
        scan.start();
    }

    // matugen's wallpaper.sh saves the choice (the file below, which updates `path`) and runs
    // matugen; `ghost theme` uses the same script.
    function set(path: string): void {
        apply.start(["sh", Quickshell.env("HOME") + "/.config/matugen/wallpaper.sh", path]);
    }

    onFolderChanged: rescan()

    LatestProcess {
        id: scan
        command: ["sh", Quickshell.shellDir + "/services/wallpapers.sh", root.folder]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const screen = Quickshell.screens[0];
                root.pictures = WallpapersJs.entries(text, screen?.width ?? 1920, screen?.height ?? 1080, root.folder);
            }
        }
    }

    // Light and dark: a picture with a dark version follows the mode (Settings'
    // wallpaperFollowsMode). Each change also remakes the colors from the picture.
    readonly property string modeWanted: Settings.values.wallpaperFollowsMode ? ColorScheme.mode : ""
    onModeWantedChanged: followMode()
    onPicturesChanged: followMode()

    function followMode(): void {
        if (modeWanted === "" || path === "")
            return;
        const picture = pictures.find(p => p.darkPath !== "" && (p.filePath === path || p.darkPath === path));
        if (!picture)
            return;
        const wanted = modeWanted === "dark" ? picture.darkPath : picture.filePath;
        if (wanted !== path)
            set(wanted);
    }

    // The slideshow: every wallpaperMinutes minutes (0 = off) a picture picked at random from
    // yours, or from all of them (wallpaperSlideshowAll). Not while the picker is open.
    readonly property int slideshowMinutes: Math.max(0, Number(Settings.values.wallpaperMinutes) || 0)

    Timer {
        interval: Math.max(1, root.slideshowMinutes) * 60 * 1000
        running: root.slideshowMinutes > 0
        repeat: true
        onTriggered: {
            if (root.pickerOpen)
                return;
            const pool = root.pictures.filter(p => (Settings.values.wallpaperSlideshowAll || p.own)
                                                   && p.filePath !== root.path && p.darkPath !== root.path);
            if (pool.length === 0)
                return;
            const picture = pool[Math.floor(Math.random() * pool.length)];
            root.set(root.modeWanted === "dark" && picture.darkPath !== "" ? picture.darkPath : picture.filePath);
        }
    }

    // Kept next to matugen's colors.json, outside the shell directory: Quickshell reloads the
    // shell when files in its own directory change. Written by wallpaper.sh.
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/wallpaper.json"
        // Missing until a wallpaper is chosen for the first time; that's fine.
        printErrors: false
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: state
            property string path: ""
        }
    }

    // From scripts: qs ipc call wallpaper set ~/Pictures/Wallpapers/forest.jpg
    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.set(path);
        }

        function get(): string {
            return root.path;
        }

        function picker(): void {
            root.pickerOpen = !root.pickerOpen;
        }
    }

    // A second pick while the first is still being colored is applied after it, not dropped.
    LatestProcess {
        id: apply
        onExited: (code, status) => {
            if (code === 0)
                return;
            // You picked it, so say so: otherwise the picker just seems to do nothing.
            console.warn("Wallpaper: wallpaper.sh exited with code " + code);
            Notifications.send("Wallpaper", "dialog-warning", "Couldn't set the wallpaper",
                               "Making its colors failed (wallpaper.sh exited with " + code + "). Run `ghost theme <picture>` in a terminal to see why.",
                               false, []);
        }
    }
}
