// Entry point: Quickshell loads ~/.config/quickshell/shell.qml.
// `import qs.<folder>` imports a folder relative to this file; files starting with an
// uppercase letter become types (bar/Bar.qml -> Bar). No qmldir needed.
import Quickshell
import qs.bar
import qs.dock
import qs.launcher
import qs.lock
import qs.osd
import qs.snap
import qs.switcher
import qs.wallpaper

ShellRoot {
    WallpaperLayer {}
    Island {}
    Dock {}
    Launcher {}
    Lock {}
    Osd {}
    SnapPicker {}
    SnapAssist {}
    Switcher {}
}
