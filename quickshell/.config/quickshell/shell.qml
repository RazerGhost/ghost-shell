// Entry point: Quickshell loads ~/.config/quickshell/shell.qml.
// `import qs.<folder>` imports a folder relative to this file; files starting with an
// uppercase letter become types (bar/Bar.qml -> Bar). No qmldir needed.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.dock
import qs.idle
import qs.launcher
import qs.lock
import qs.osd
import qs.overview
import qs.polkit
import qs.screenshot
import qs.services
import qs.settings
import qs.snap
import qs.switcher
import qs.customize
import qs.desktop
import qs.wallpaper
import qs.welcome

ShellRoot {
    WallpaperLayer {}
    DesktopWidgets {}
    WallpaperPicker {}
    Island {}
    Dock {}
    Launcher {}
    Lock {}
    Customize {}
    LoginScreenSync {}
    PolkitPrompt {}
    Welcome {}
    Screenshot {}
    Osd {}
    Overview {}
    WindowMenu {}
    SnapAssist {}
    Switcher {}
    Idle {}
    HyprlandSettings {}

    // Background services that are singletons, so they only run once something uses them: low
    // battery, disk space and out-of-memory warnings, the touchpad's mouse rule, the equalizer's gains, screen
    // time, sound events (the charger and USB devices) and light or dark at sunset.
    Component.onCompleted: {
        BatteryAlerts.check();
        DiskAlerts.given;
        OomAlerts.watching;
        Touchpad.enabled;
        Equalizer.gains;
        ScreenTime.loaded;
        Sounds.ready;
        ColorScheme.mode;
    }

    // The system's default apps follow the settings (services/Apps.qml).
    Connections {
        target: Settings

        function onLoadedChanged(): void {
            if (Settings.loaded)
                Apps.applySystemDefaults();
        }
    }

    // Here because the settings window is a singleton, which only exists once something uses it.
    IpcHandler {
        target: "settings"

        function open(): void {
            SettingsWindow.open = true;
        }

        // A page by its id ("lock", "appearance", ...; SettingsWindow's list).
        function page(name: string): void {
            SettingsWindow.page = name;
            SettingsWindow.open = true;
        }
    }

    // The Wallpapers window, a singleton like the settings window.
    IpcHandler {
        target: "wallpapers"

        function browse(): void {
            WallpaperBrowser.open = true;
        }
    }
}
