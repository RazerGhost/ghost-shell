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

            // Pop-ups (Settings -> Notifications): how long a notification stays (seconds; critical
            // ones stay until dismissed), and the OSD's place ("bottom" or "top") and time.
            // The island's status icons you've hidden, by key (bar/StatusIcons.qml); the privacy
            // ones (recording, microphone, camera, screen sharing) always show.
            property var hiddenStatusIcons: []
            property real notificationSeconds: 5
            property string osdPosition: "bottom"
            property real osdSeconds: 1.5

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
            property bool greeterShowName: true     // your user name above the password field
            property bool greeterPowerButtons: true // suspend, restart and shut down

            property bool hotCorner: true // the pointer in the top-left corner opens the overview

            property bool batterySaver: true // power saver from the low battery warning until plugged in
            property bool clock24Hour: true // the island's and the lock screen's clock ("9:41 PM" off)

            // The town for the weather in the today menu (services/Weather.qml); "" = no weather.
            property string weatherLocation: ""

            // "dark", "light" or "auto" (dark from sunset to sunrise; services/ColorScheme.qml).
            property string colorScheme: "dark"
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
