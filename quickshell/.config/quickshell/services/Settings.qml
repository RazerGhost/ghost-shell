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

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"
        // The file loads a moment after the shell starts: until then the values below are the
        // defaults, so read them in bindings, which update once it's loaded.
        printErrors: false // missing until the first change
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.loaded = true
        onLoadFailed: root.loaded = true

        adapter: JsonAdapter {
            id: adapter

            // Times are minutes since midnight (services/Schedule.js).
            property bool nightLightScheduled: false
            property int nightLightStart: 20 * 60
            property int nightLightEnd: 7 * 60
            property int nightLightTemperature: 4000 // Kelvin; lower is warmer

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
            property bool lock24Hour: true
            property bool greeterShowName: true     // your user name above the password field
            property bool greeterPowerButtons: true // suspend, restart and shut down

            // Hyprland's options (settings/HyprlandSettings.qml writes them to shell-settings.lua).
            // The defaults are input.lua's and look.lua's.
            property string keyboardLayout: "us" // XKB codes, e.g. "us" or "us,nl"
            property real pointerSpeed: 0        // -1 (slow) to 1 (fast), mouse and touchpad
            property bool naturalScroll: false   // the touchpad's
            property bool tapToClick: true
            property int gapsIn: 5               // between windows
            property int gapsOut: 20             // between windows and the screen's edges
            property int borderSize: 2
            property int rounding: 10            // window corners
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
