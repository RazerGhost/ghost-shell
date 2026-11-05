// The user's settings (Settings changes them), saved in
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

    // One save per burst of changes (see the FileView below).
    Timer {
        id: save
        interval: 0
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/settings.json"
        // The file loads a moment after the shell starts: until then the values below are the
        // defaults, so read them in bindings, which update once it's loaded.
        printErrors: false // missing until the first change
        watchChanges: true
        // Saved once per burst of changes (a preset sets up to a dozen at once), written before
        // anything reads it, and not read back while a save waits: saving after each change
        // in the background let the re-read of an early save bring back old values for the
        // later ones (verified 2026-10-30: of six set in a row, three were kept; NOTES).
        blockWrites: true
        onFileChanged: {
            if (!save.running)
                reload();
        }
        onAdapterUpdated: {
            if (root.writable)
                save.restart();
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

            // The status icons you've hidden, by key (quick settings' controlcenter/StatusIcons.qml,
            // and the island's timer, bar/IslandAlerts.qml); the privacy ones (recording,
            // microphone, camera, screen sharing) always show in the island.
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

            // The lock screen (lock/LockContent.qml): your desktop, locked, with this line at the bottom.
            property string lockMessage: ""       // "If found, call ..."

            // Quick settings' tiles and round buttons, in order (controlcenter/QuickItems.js);
            // until edited, its defaults.
            property var quickTiles: null
            property var quickToggles: null
            property var quickLarge: []  // wide tiles taking the whole row (made large in edit mode)

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
            // The island floats below the top edge; attached, it grows out of the edge (the dock
            // and island editor).
            property bool islandAttached: false
            // The town for the weather in the today menu (services/Weather.qml); "" = no weather.
            property string weatherLocation: ""
            property string temperatureUnit: "celsius" // or "fahrenheit"

            // Wallpapers (Settings -> Appearance): your folder ("" = ~/Pictures/Wallpapers), a
            // slideshow every so many minutes (0 = off), and switching a
            // picture with a dark version along with light and dark.
            property string wallpaperFolder: ""
            property int wallpaperMinutes: 0
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
            // Hyprland's blur with a thin light edge (like the Ghost Spotify theme), or solid.
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
            // The windows' extras (settings/HyprlandConfig.js lists the styles).
            property string windowAnimation: "popin"   // popin, slide, gnomed
            property string workspaceAnimation: "fade" // fade, slide, slidevert, slidefade
            property bool borderSpin: false        // the border's colors turn (redraws all the time)
            property bool windowGlow: false        // a glow inside the focused window's edge
            property bool windowKindBorders: false // floating and pinned windows' own border colors
            // Desktop widgets (desktop/DesktopWidgets.qml) and where each was dragged:
            // { clock: { x, y }, ... } as fractions of the screen.
            property bool desktopClock: false
            property bool desktopWeather: false
            property bool desktopMedia: false
            property bool desktopCalendar: false
            property bool desktopBattery: false
            property bool desktopTodo: false
            property bool desktopTimer: false
            property bool desktopNotifications: false
            property bool desktopForecast: false
            property bool desktopMonth: false
            property bool desktopTasks: false
            property bool desktopNote: false
            property bool desktopClipboard: false
            // What a new terminal shows (bin/.local/bin/ghost-greeting reads it from this
            // file): "ghost" (fastfetch with the Ghost look), "line" (one line) or "none".
            property string terminalGreeting: "ghost"
            // Settings -> Terminal: the prompt's style (settings/TerminalConfig.js `prompts`; .zshrc
            // reads it), Ghostty's cursor trail and notifications when a long command ends.
            property string terminalPrompt: "pills"
            property bool terminalCursorTrail: true
            property bool terminalNotify: true
            property int focusMinutes: 25 // focus mode's length, the one picked last
            // The music app last heard (its desktop entry id), which the media widget offers to
            // open while nothing plays (services/Media.qml).
            property string lastMediaApp: ""
            // The launcher's Settings and Wallpapers pages: "compact", "large" or "full"
            // (services/LauncherState.qml).
            property string launcherPanelSize: "large"
            // The grid widgets line up with when dropped (desktop/DesktopWidgets.js), and its
            // spacing in px at 100 %.
            property bool desktopGrid: false
            property int desktopGridSize: 32
            property var desktopWidgets: ({})
            // Your saved looks (customize/Themes.js): [{ name, wallpaper, primary, values }].
            property var themes: []
            // Your own looks in the editors' Looks galleries (customize/SavedLooks.js): [{ name, values }].
            property var dockLooks: []
            property var windowLooks: []
            property var widgetLooks: []
            property string cursorTheme: ""        // "" = Adwaita
            property int cursorSize: 24
            property bool cursorHideTyping: false // hide the pointer while typing
            property int cursorHideAfter: 0       // seconds still before it hides; 0 = never
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
            // The laptop's screen at its lowest refresh rate while on battery (quick settings' Display page).
            property bool displayLowRefreshOnBattery: false
            // The main screen by output name ("": the laptop's own, else the first; services/Screens.qml),
            // and the dock on every screen instead of only there.
            property string mainScreen: ""
            property bool dockEverywhere: false
            // With several screens, each its own workspaces: the main one 1-5, the next 6-10 (Display.qml).
            property bool workspacesPerScreen: true
            // Where the screens sit, per set of connected screens: { setKey: { key: "XxY" } }
            // (settings/DisplayModes.js `setKey`, `key`, `arranged`; Settings -> Display).
            property var screenLayouts: ({})
            // The VPN connected last, by name: quick settings' VPN switch reconnects it.
            property string lastVpn: ""
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
            // Seconds after the idle lock in which a touch unlocks without the password; 0 = off.
            property int lockGrace: 0
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
