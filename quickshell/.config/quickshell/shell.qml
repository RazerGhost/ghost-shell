// Entry point: Quickshell loads ~/.config/quickshell/shell.qml.
// `import qs.<folder>` imports a folder relative to this file; files starting with an
// uppercase letter become types (bar/Bar.qml -> Bar). No qmldir needed.
import Quickshell
import qs.bar
import qs.launcher
import qs.osd
import qs.wallpaper

ShellRoot {
    WallpaperLayer {}
    Island {}
    Launcher {}
    Osd {}
}
