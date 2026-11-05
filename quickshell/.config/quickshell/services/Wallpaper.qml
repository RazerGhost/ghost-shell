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
import "../desktop/DesktopWidgets.js" as DesktopWidgetsJs
import "../settings/DisplayModes.js" as DisplayModes

Singleton {
    id: root

    // Your folder (Settings' wallpaperFolder; ~/Pictures/Wallpapers by default).
    readonly property string folder: CaptureFolders.folder(Settings.values.wallpaperFolder, Quickshell.env("HOME"),
                                                           Quickshell.env("HOME") + "/Pictures/Wallpapers")
    // The current wallpaper's path; "" until one is chosen (Hyprland's default shows then).
    readonly property string path: state.path
    // Its file has been read (or isn't there): until then `path` is "" whatever was chosen.
    property bool loaded: false
    // A live wallpaper (a video), and the still picture for it: a frame that matugen's
    // wallpaper.sh made (the colors come from it; the lock screen shows it).
    readonly property bool isVideo: WallpapersJs.isVideo(path)
    function isVideoPath(file: string): bool {
        return WallpapersJs.isVideo(file);
    }
    readonly property string stillPath: isVideo ? Quickshell.env("HOME") + "/.local/state/quickshell/video-frame.jpg" : path
    // The picker strip is open (wallpaper/WallpaperPicker.qml): quick settings' button, or
    // `qs ipc call wallpaper picker`.
    property bool pickerOpen: false

    // Every picture to choose from, as { filePath, fileName, darkPath, own }: the ones in your
    // folder (the system's collections aren't offered; the launcher's Wallpapers page finds more). Found
    // by services/wallpapers.sh and grouped by Wallpapers.js (tested): a Plasma picture at your
    // screen's size, dark versions paired with their light ones.
    property var pictures: []
    readonly property int ownCount: pictures.filter(p => p.own).length

    // Look again (pickers call this when they open): new pictures, a new folder.
    function rescan(): void {
        scan.start();
    }

    // A new wallpaper's colors are being made (wallpaper.sh runs matugen; about a second), or
    // it waits for the color scheme's run.
    readonly property bool busy: apply.running || waiting !== null
    // wallpaper.sh runs for the wallpaper now (not just waiting): ColorScheme waits for it.
    readonly property bool running: apply.running

    // The wallpaper last asked for ("" for none). `path` only changes once wallpaper.sh has
    // written it (for a video, after its frame is made), so the desktop editor's Cancel and
    // themes compare with `target`: the one asked for while it's on its way, else `path`.
    property string requested: ""
    readonly property string target: busy ? requested : path
    // wallpaper.sh's argument while it waits for ColorScheme's run to end (null: nothing waits).
    property var waiting: null

    // matugen's wallpaper.sh saves the choice (the file below, which updates `path`) and runs
    // matugen; `ghost theme` uses the same script.
    function set(path: string): void {
        run(path, path);
    }

    // A wallpaper per screen (Settings -> Display, with several screens: `wallpaperPerScreen`):
    // the main screen's is `path`, which makes the colors; another screen shows its own picture
    // from `screenWallpapers` (by output name) or, until one is picked for it, the main one's.
    // A live one plays there by the same rules; its thumbnail is its still frame (stillFor).
    readonly property bool perScreen: Settings.values.wallpaperPerScreen === true && Screens.several
    // Saved per monitor (its make, model and serial: DisplayModes.key), so it follows the monitor
    // to another port; under the port's name before that.
    function screenKey(screenName: string): string {
        const m = Display.monitors.find(m => m.name === screenName);
        return m ? DisplayModes.key(m, Display.monitors) : screenName;
    }
    function pathFor(screenName: string): string {
        if (!perScreen || screenName === (Screens.main?.name ?? ""))
            return path;
        const own = Settings.values.screenWallpapers?.[screenKey(screenName)] ?? Settings.values.screenWallpapers?.[screenName];
        return typeof own === "string" && own !== "" ? own : path;
    }
    // The still picture for another screen's own wallpaper: a video's thumbnail (made when the
    // folder is scanned), a picture itself.
    function stillFor(file: string): string {
        return WallpapersJs.isVideo(file) ? (pictures.find(p => p.filePath === file)?.thumb ?? "") : file;
    }

    // Picking a wallpaper on a screen (the island's strip opens on the screen you're on): the
    // main screen's, or with one per screen another's.
    function setFor(screenName: string, picture: string): void {
        if (!perScreen || screenName === (Screens.main?.name ?? "")) {
            set(picture);
            return;
        }
        Settings.values.screenWallpapers = Object.assign({}, Settings.values.screenWallpapers, { [screenKey(screenName)]: picture });
    }

    // No wallpaper again (Hyprland's default shows), colors from the last seed color: the desktop
    // editor's Cancel when none was chosen before it opened.
    function clear(): void {
        run("--none", "");
    }

    // After the color scheme's own run when one is coming (a theme or Cancel changes the colors'
    // settings and the wallpaper at once): both run wallpaper.sh, and side by side the one
    // reading the old scheme could finish last.
    function run(argument: string, wanted: string): void {
        requested = wanted;
        if (ColorScheme.busy) {
            waiting = argument;
            return;
        }
        apply.start(["sh", Quickshell.env("HOME") + "/.config/matugen/wallpaper.sh", argument]);
    }

    Connections {
        target: ColorScheme

        function onBusyChanged(): void {
            if (ColorScheme.busy || root.waiting === null)
                return;
            const argument = root.waiting;
            root.waiting = null;
            apply.start(["sh", Quickshell.env("HOME") + "/.config/matugen/wallpaper.sh", argument]);
        }
    }

    onFolderChanged: rescan()

    LatestProcess {
        id: scan
        command: ["sh", Quickshell.shellDir + "/services/wallpapers.sh", root.folder]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const screen = Screens.main;
                root.pictures = WallpapersJs.entries(text, screen?.width ?? 1920, screen?.height ?? 1080, root.folder);
            }
        }
    }

    // Light and dark: a picture with a dark version follows the mode the colors were last made
    // in (Settings' wallpaperFollowsMode; ColorScheme.appliedMode). Each change also remakes the
    // colors from the picture.
    readonly property string modeWanted: Settings.values.wallpaperFollowsMode ? ColorScheme.appliedMode : ""
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

    // The slideshow: every wallpaperMinutes minutes (0 = off) a picture of yours picked at
    // random. Not while you're choosing one yourself: the picker, the desktop editor (whose Done
    // would keep the slideshow's pick) or the Wallpapers page.
    readonly property int slideshowMinutes: Math.max(0, Number(Settings.values.wallpaperMinutes) || 0)

    Timer {
        interval: Math.max(1, root.slideshowMinutes) * 60 * 1000
        running: root.slideshowMinutes > 0
        repeat: true
        onTriggered: {
            if (root.pickerOpen || Editing.desktop || (LauncherState.open && LauncherState.page === "wallpapers"))
                return;
            const pool = root.pictures.filter(p => p.filePath !== root.path && p.darkPath !== root.path);
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
        onLoaded: root.loaded = true
        onLoadFailed: root.loaded = true

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

    // Which side of the picture is calmer ("left", "right" or ""), for placing widget layouts
    // around its subject (customize/Presets.js widgetPresets). ffmpeg shrinks it to 48 x 27 grey
    // pixels (a fraction of a second, once per wallpaper); DesktopWidgets.quietSide compares them.
    property string quietSide: ""
    onStillPathChanged: measure()
    // A video's frame is remade at the same path after the wallpaper changes.
    onBusyChanged: {
        if (!busy)
            measure();
    }
    Component.onCompleted: measure()

    function measure(): void {
        if (stillPath === "") {
            quietSide = "";
            return;
        }
        quietCheck.start(["sh", "-c", 'ffmpeg -v error -i "$1" -vf scale=48:27,format=gray -frames:v 1 -f rawvideo - | od -An -tu1 -v',
                          "sh", stillPath]);
    }

    LatestProcess {
        id: quietCheck
        stdout: StdioCollector {
            onStreamFinished: {
                const gray = text.trim().split(/\s+/).map(Number).filter(n => !isNaN(n));
                root.quietSide = DesktopWidgetsJs.quietSide(gray, 48, 27);
            }
        }
    }
}
