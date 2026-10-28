// Entry point: Quickshell loads ~/.config/quickshell/shell.qml.
// `import qs.<folder>` imports a folder relative to this file; files starting with an
// uppercase letter become types (bar/Bar.qml -> Bar). No qmldir needed.
import Quickshell
import Quickshell.Io
import qs.bar
import qs.dock
import qs.idle
import qs.launcher
import qs.lock
import qs.osd
import qs.settings
import qs.snap
import qs.switcher
import qs.wallpaper

ShellRoot {
    WallpaperLayer {}
    Island {}
    Dock {}
    Launcher {}
    Lock {}
    LoginScreenSync {}
    Osd {}
    SnapPicker {}
    SnapAssist {}
    Switcher {}
    Idle {}

    // Here because the settings window is a singleton, which only exists once something uses it.
    IpcHandler {
        target: "settings"

        function open(): void {
            SettingsWindow.open = true;
        }
    }
}
