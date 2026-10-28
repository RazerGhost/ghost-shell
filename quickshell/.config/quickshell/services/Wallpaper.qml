// The wallpaper: an image from ~/Pictures/Wallpapers, drawn by wallpaper/WallpaperLayer.qml.
// Choosing one also runs matugen on it, which recolors the shell, Hyprland, Ghostty, GTK and
// Yazi from the picture.
pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    // The current wallpaper's path; "" until one is chosen (Hyprland's default shows then).
    readonly property string path: state.path
    // The lock and login screens' picture: the one chosen in settings, or else the desktop's.
    readonly property string lockPath: Settings.values.lockWallpaper || path
    // The picker strip is open (wallpaper/WallpaperPicker.qml): quick settings' button, or
    // `qs ipc call wallpaper picker`.
    property bool pickerOpen: false

    // Every picture to choose from, as { filePath, fileName }: yours from ~/Pictures/Wallpapers
    // first, then the built-in ones that come with Hyprland and CachyOS (from their packages,
    // so they're not copied anywhere). Reading each folder's count keeps this up to date.
    readonly property var pictures: files(yours).concat(files(hyprland), files(cachyos))
    readonly property int ownCount: yours.count

    function files(model: FolderListModel): var {
        const list = [];
        for (let i = 0; i < model.count; i++)
            list.push({ filePath: model.get(i, "filePath"), fileName: model.get(i, "fileName") });
        return list;
    }

    // Re-read your folder (pickers call this when they open): the folder listing doesn't notice
    // the folder being created after the shell started (e.g. by "Open folder").
    function rescan(): void {
        yours.folder = "";
        yours.folder = "file://" + folder;
    }

    // matugen's wallpaper.sh saves the choice (the file below, which updates `path`) and runs
    // matugen; `dots theme` uses the same script.
    function set(path: string): void {
        apply.command = ["sh", Quickshell.env("HOME") + "/.config/matugen/wallpaper.sh", path];
        apply.running = true;
    }

    FolderListModel {
        id: yours
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    FolderListModel {
        id: hyprland
        folder: "file:///usr/share/hypr"
        nameFilters: ["wall*.png"] // the folder also holds other images
        showDirs: false
    }

    FolderListModel {
        id: cachyos
        folder: "file:///usr/share/wallpapers/cachyos-wallpapers"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
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

    Process {
        id: apply
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("Wallpaper: wallpaper.sh exited with code " + code);
        }
    }
}
