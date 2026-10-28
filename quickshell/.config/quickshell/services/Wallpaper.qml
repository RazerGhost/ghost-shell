// The wallpaper: an image from ~/Pictures/Wallpapers, drawn by wallpaper/WallpaperLayer.qml.
// Choosing one also runs matugen on it, which recolors the shell, Hyprland, Ghostty, GTK and
// Yazi from the picture.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    // The current wallpaper's path; "" until one is chosen (Hyprland's default shows then).
    readonly property string path: state.path

    function set(path: string): void {
        state.path = path;
        file.writeAdapter();
        matugen.command = ["matugen", "image", path, "-m", "dark", "--source-color-index", "0"];
        matugen.running = true;
    }

    // Kept next to matugen's colors.json, outside the shell directory: Quickshell reloads the
    // shell when files in its own directory change.
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/wallpaper.json"
        // Missing until a wallpaper is chosen for the first time; that's fine.
        printErrors: false

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
    }

    Process {
        id: matugen
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("Wallpaper: matugen exited with code " + code);
        }
    }
}
