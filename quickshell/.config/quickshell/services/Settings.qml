// The user's settings (the settings window changes them), saved in
// ~/.local/state/quickshell/settings.json: outside the shell directory, since a change there
// would reload the shell. Read them as Settings.values.<name>; assigning one saves the file.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property JsonAdapter values: adapter
    // The file has been read (or found missing, so the defaults below apply).
    property bool loaded: false
    // Changes are saved. Not when the file is there but isn't valid JSON: Quickshell then loads
    // the defaults without an error (verified), and saving would write them over the user's file.
    // That file is kept as settings.json.bad and the user is told; changes last until a restart.
    property bool writable: false

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"
        // The file loads a moment after the shell starts: until then the values below are the
        // defaults, so read them in bindings, which update once it's loaded.
        printErrors: false // missing until the first change
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: {
            if (root.writable)
                writeAdapter();
        }
        onLoaded: {
            const text = file.text();
            let valid = true;
            try {
                if (text.trim() !== "")
                    JSON.parse(text);
            } catch (e) {
                valid = false;
            }
            // Warn once: at start, or when a good file turns bad (a hand edit), not again after.
            if (!valid && (root.writable || !root.loaded)) {
                Quickshell.execDetached(["cp", "-f", path, path + ".bad"]);
                Notifications.send("Settings", "dialog-warning", "Your settings file couldn't be read",
                                   "It's kept as settings.json.bad. Settings use their defaults and aren't saved until it's fixed or removed.",
                                   true, []);
            }
            root.writable = valid;
            root.loaded = true;
        }
        onLoadFailed: error => {
            // Missing: the defaults apply and the first change creates it. Anything else: leave it.
            root.writable = error === FileViewError.FileNotFound;
            root.loaded = true;
        }

        adapter: JsonAdapter {
            id: adapter

            // Times are minutes since midnight (services/Schedule.js).
            property bool nightLightScheduled: false
            property int nightLightStart: 20 * 60
            property int nightLightEnd: 7 * 60
            property int nightLightTemperature: 4000 // Kelvin; lower is warmer

            // The island's status icons you've hidden, by key (bar/StatusIcons.qml); the privacy
            // ones (recording, microphone, camera, screen sharing) always show.
            property var hiddenStatusIcons: []
            // The dock: "hide" (shows at the bottom edge), "always" (reserves its space) or "off".
            property string dockMode: "hide"
            property int dockIconSize: 44  // px at 100 % (theme/ThemeScale.js lists the sizes)
            property int launcherWidth: 560
            property int launcherRows: 8
            // The launcher (Settings -> Default apps): starred and hidden apps by desktop entry id,
            // and your own commands, [{ name, command }].
            property var launcherFavorites: []
            property var launcherHidden: []
            property var launcherCommands: []
            property int workspaceDots: 5  // always shown; 0 = only the ones in use
            // Pop-ups (Settings -> Notifications): how long a notification stays (seconds; critical
            // ones stay until dismissed), and the OSD's place ("bottom" or "top") and time.
            property real notificationSeconds: 5
            property string osdPosition: "bottom"
            property var hiddenOsdKinds: [] // pop-ups turned off, by key (osd/Osd.qml)
            property real osdSeconds: 1.5

            property bool dndFullscreen: true // pop-ups wait while a window is fullscreen
            property bool dndScheduled: false
            property int dndStart: 23 * 60
            property int dndEnd: 7 * 60

            // Minutes without input before each step; 0 = never.
            property int idleBatteryDim: 4
            property int idleBatteryLock: 5
            property int idleBatteryScreenOff: 6
            property int idleBatterySuspend: 15
            property int idleAcDim: 4
            property int idleAcLock: 5
            property int idleAcScreenOff: 6
            property int idleAcSuspend: 0

            // The lock screen and the login screen (both drawn by lock/LockContent.qml; the login
            // screen gets a copy of this file, see greeter/sync.sh).
            property string lockWallpaper: "" // a picture's path; "" = the desktop's wallpaper
            property int lockBlur: 100        // percent of Theme.lock.blur
            property int lockDim: 25          // percent darker
            property bool lockClock: true
            property bool lockDate: true
            // The clock's look and place (lock/LockClock.js has the choices).
            property string lockClockStyle: "big" // big, stacked, thin, analog
            property int lockClockSize: 100       // percent
            property string lockClockFont: ""     // "" = the shell's text font
            property string lockLayout: "top"     // top, center, left (the bottom-left corner)
            property bool greeterShowName: true     // your user name above the password field
            property bool greeterPowerButtons: true // suspend, restart and shut down

            property bool hotCorner: true // the pointer in the top-left corner opens the overview

            property bool batterySaver: true // power saver from the low battery warning until plugged in
            property bool clock24Hour: true // the island's and the lock screen's clock ("9:41 PM" off)

            // Screenshots and recordings: folders ("" = ~/Pictures/Screenshots, ~/Videos/Recordings),
            // the recording's frame rate, quality (gpu-screen-recorder's presets) and whether the
            // microphone is mixed in with the desktop's sound.
            property string screenshotFolder: ""
            property string recordingFolder: ""
            property int recordingFps: 60
            property string recordingQuality: "very_high"
            property bool recordingMic: false
            // The island's clock: the day ("Thu 29") and seconds too; and whether playing music
            // takes the clock's place (its cover).
            property bool clockDate: false
            property bool clockSeconds: false
            property bool islandMedia: true
            // The town for the weather in the today menu (services/Weather.qml); "" = no weather.
            property string weatherLocation: ""
            property string temperatureUnit: "celsius" // or "fahrenheit"

            // Wallpapers (Settings -> Appearance): your folder ("" = ~/Pictures/Wallpapers), a
            // slideshow every so many minutes (0 = off) from yours or from all, and switching a
            // picture with a dark version along with light and dark.
            property string wallpaperFolder: ""
            property int wallpaperMinutes: 0
            property bool wallpaperSlideshowAll: false
            property bool wallpaperFollowsMode: true
            // "dark", "light" or "auto" (dark from sunset to sunrise; services/ColorScheme.qml).
            property string colorScheme: "dark"
            // matugen's color style (a scheme type, ColorScheme.js), contrast (-1 to 1) and a
            // fixed accent color ("#rrggbb"; "" = the wallpaper's).
            property string colorStyle: "scheme-tonal-spot"
            property real colorContrast: 0
            property string accentColor: ""
            // The shell's fonts: UI text and the monospaced one ("" = Inter and MesloLGS Nerd Font).
            // The icon theme ("Colloid", "Colloid-Teal", "breeze", ...); its dark or light version
            // follows the mode (matugen's wallpaper.sh).
            property string iconTheme: "Colloid"
            property string fontSans: ""
            property string fontMono: ""
            // The shell's panels (island, menus, dock, launcher...): glass, see-through over
            // Hyprland's blur with a thin light edge (like the Ghost Spotify theme), or nearly solid.
            property bool glass: true
            property int glassOpacity: 45 // percent, 20-85 (settings/AppearancePage.qml)

            // Hyprland's options (settings/HyprlandSettings.qml writes them to shell-settings.lua).
            // The defaults are input.lua's and look.lua's.
            property string keyboardLayout: "us" // XKB codes, e.g. "us" or "us,nl"
            property real pointerSpeed: 0        // -1 (slow) to 1 (fast), mouse and touchpad
            property bool naturalScroll: false   // the touchpad's
            property bool tapToClick: true
            property bool touchpadOffWithMouse: false // services/Touchpad.qml
            property int gapsIn: 5               // between windows
            property int gapsOut: 20             // between windows and the screen's edges
            property int borderSize: 2
            property int rounding: 10            // window corners
            // Settings -> Appearance -> Size (theme/ThemeScale.js lists the steps).
            property real uiScale: 1
            property real textScale: 1
            property real cornerScale: 1
            property real animationSpeed: 1 // 0 = off, 0.5-2 (HyprlandConfig.animationSpeeds)
            property string blurStyle: "kawase"  // Hyprland's blur variant (HyprlandConfig.js lists them)
            property bool wobble: false          // windows wobble while moved or resized
            // Screens set up in Settings -> Display, by output name: { mode, scale, transform, vrr }
            // (settings/DisplayModes.js); the others use monitors.lua's "preferred".
            property var monitors: ({})
            // Per-app notifications, by app name: { mode } (services/NotificationRules.js).
            property var notificationApps: ({})
            // Equalizer gains in dB per output, by PipeWire node name (services/Equalizer.qml).
            property var equalizer: ({})
            // Sound events (services/Sounds.qml): all of them, then each kind.
            property bool soundEvents: true
            property bool soundNotifications: true
            property bool soundDevices: true    // charger, USB
            property bool soundFeedback: true   // volume keys, screenshots
            property bool soundBattery: true    // low battery
            // Under the clock on the lock screen (lock/LockStatus.qml); never on the login screen.
            property bool lockMedia: true
            property bool lockNotificationCount: true
            property bool lockWeather: true
            property bool lockBattery: true
            property bool lockEvent: false // its title shows to anyone at the locked screen
            property bool welcomeSeen: false // the welcome tour (welcome/Welcome.qml) has been shown
            property bool rememberPositions: true // floating apps reopen where they were (positions.lua)

            // Desktop entry ids of the apps Super+Enter, Super+B and Super+E open, and of the apps
            // pictures, videos and audio files open in.
            property string terminal: "com.mitchellh.ghostty"
            property string browser: "zen"
            property string fileManager: "org.gnome.Nautilus"
            property string editor: "dev.zed.Zed"
            property string imageViewer: "org.gnome.Loupe" // screenshots open in it
            property string videoPlayer: "io.github.celluloid_player.Celluloid"
            property string audioPlayer: "io.github.celluloid_player.Celluloid"
        }
    }
}
