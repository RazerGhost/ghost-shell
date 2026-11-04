// Design tokens: spacing, radius, fonts, sizes, animation. Colors live in Colors.qml.
// Components use these instead of hardcoded numbers so the look can be tuned in one place.
pragma Singleton

import QtQuick
import Quickshell
import qs.services
import "../settings/HyprlandConfig.js" as HyprlandConfig
import "../desktop/DesktopWidgets.js" as DesktopWidgetsJs
import "ThemeScale.js" as ThemeScale

Singleton {
    id: root

    // Settings -> Appearance -> Size (ThemeScale.js, tested): the shell's sizes, its text on top
    // of that, and its corners. Timings, counts and outline widths don't change.
    readonly property real scale: ThemeScale.pick(Settings.values.uiScale, ThemeScale.sizes)
    readonly property real textScale: ThemeScale.pick(Settings.values.textScale, ThemeScale.textSizes)
    readonly property real cornerScale: ThemeScale.pick(Settings.values.cornerScale, ThemeScale.corners)

    function px(base: int): int {
        return ThemeScale.px(base, scale);
    }
    function text(base: int): int {
        return ThemeScale.px(base, scale * textScale);
    }
    function round(base: int): int {
        return ThemeScale.radius(base, scale, cornerScale);
    }
    readonly property QtObject spacing: QtObject {
        readonly property int xs: root.px(4)
        readonly property int s:  root.px(8)
        readonly property int m:  root.px(12)
        readonly property int l:  root.px(16)
    }

    readonly property QtObject radius: QtObject {
        readonly property int s:    root.round(8)
        readonly property int m:    root.round(12)
        readonly property int l:    root.round(20)
        readonly property int xl:   root.round(28)
        readonly property int full: root.round(999) // clamped to half the height: a pill
    }

    readonly property QtObject font: QtObject {
        // Settings -> Appearance -> Fonts; Inter and MesloLGS by default.
        readonly property string defaultSans: "Inter" // also a theme card's font when it kept the default
        readonly property string sans: Settings.values.fontSans || defaultSans
        readonly property string mono: Settings.values.fontMono || "MesloLGS Nerd Font" // error messages
        readonly property string emoji: "Noto Color Emoji"
        readonly property string icon: "Material Symbols Rounded"
        readonly property int iconWeight: 300 // Material Symbols line weight (400 is the font's default)

        readonly property int small:  root.text(11)
        readonly property int normal: root.text(13)
        readonly property int large:  root.text(16)
        readonly property int title:  root.text(22)
    }

    readonly property QtObject icon: QtObject {
        readonly property int small:    root.px(16) // status icons (quick settings, the island's alerts)
        readonly property int normal:   root.px(20) // buttons, tiles, sliders
        readonly property int launcher: root.px(32) // app icons in the launcher list
        readonly property int osd:      root.px(18) // the OSD's icon
    }

    // Durations follow Settings' animation speed (2 = twice as fast, 0 = none; the same factor
    // as Hyprland's, HyprlandConfig.js).
    readonly property QtObject anim: QtObject {
        readonly property real speed: HyprlandConfig.animationSpeed(Settings.values.animationSpeed)
        readonly property int fast:   speed > 0 ? Math.round(150 / speed) : 0
        readonly property int normal: speed > 0 ? Math.round(250 / speed) : 0
        readonly property int easing: Easing.OutCubic

        // The island's open/close morph: Material 3's "emphasized decelerate" curve, which
        // starts fast and settles gently. Used with easing.type: Easing.BezierSpline.
        readonly property int morph: speed > 0 ? Math.round(450 / speed) : 0
        // The shell's colors fading to a new wallpaper's (Colors.qml).
        readonly property int recolor: speed > 0 ? Math.round(800 / speed) : 0
        readonly property list<real> emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    }

    // How long a "click again to confirm" button waits for the second click (ms): the power
    // menu's restart and shut down, End task.
    readonly property int confirmTimeout: 4000

    // Logging out, restarting or shutting down (lock/SessionEnd.qml).
    readonly property QtObject session: QtObject {
        readonly property int countdown: 5   // s to change your mind before the apps are asked to close
        readonly property int patience: 6000 // ms the apps get to close before they're listed
        readonly property int settle:   700  // ms the screen shows once they're closed
        readonly property int width:    root.px(380)
        readonly property int ring:     root.px(88)
        readonly property int icon:     root.px(36)
        readonly property real shade:   0.95  // how much the screens dim
        readonly property real arc:     0.25  // the turning ring's length, of a full circle
        readonly property int release:  200   // ms between letting go of the keyboard and showing an app
        readonly property int turn:     root.anim.speed > 0 ? Math.round(1200 / root.anim.speed) : 0 // ms per turn
    }

    // The on/off switch (widgets/Switch.qml), Material 3's size.
    readonly property QtObject toggle: QtObject {
        readonly property int width:  root.px(52)
        readonly property int height: root.px(32)
        readonly property int border: 2 // the outline while off
        readonly property int thumbOff: root.px(16)
        readonly property int thumbOn: root.px(24)
        readonly property int thumbPressed: root.px(28) // grows while held, like Material 3's
    }

    // A tooltip (widgets/Tooltip.qml): how long the pointer rests before it shows, and its gap.
    readonly property QtObject tooltip: QtObject {
        readonly property int delay: 500 // ms
        readonly property int gap: root.px(4)
    }

    // Outlines that mark a picture or window: the chosen one, and one hovered or picked with the
    // keyboard (wallpaper and lock pictures, overview and switcher previews).
    readonly property QtObject outline: QtObject {
        readonly property int strong: 3
        readonly property int normal: 2
    }

    // The ring around the control that has the keyboard (widgets/FocusRing.qml).
    readonly property QtObject focus: QtObject {
        readonly property int width: 2
    }

    // Material "state layers": the content color laid over a control at this opacity.
    readonly property QtObject state: QtObject {
        readonly property real hover:  0.08 // the pointer is over it
        readonly property real active: 0.14 // its menu is open (the island's buttons)
        readonly property real disabled: 0.4 // can't be used right now
        readonly property real subtitle: 0.8 // a second line on a colored card or tile
    }

    // Backgrounds of the island, menus, launcher, OSD...; Hyprland blurs what's behind them. This
    // is the opacity with the glass setting off; with it on, the setting's (Colors.surfaceTranslucent).
    readonly property real surfaceOpacity: 0.85

    readonly property QtObject glass: QtObject {
        readonly property int edge: 1          // the thin light line around glass panels
        readonly property real edgeAlpha: 0.08 // its strength: the text color at 8 %
    }

    readonly property QtObject island: QtObject {
        readonly property int height:     root.px(36)  // when closed; also the space reserved at the top
        readonly property int padding:    root.px(14)  // left/right padding inside the closed island
        // The whole island moves this many px right of the screen's middle: the laptop's webcam
        // sits a pixel right of the panel's exact middle (the user lined it up by eye).
        readonly property int offset:     1
        readonly property int fillet:     root.px(14)  // radius of the concave joins to the screen edge
        // Floating (the default) or attached to the top edge (Settings' islandAttached).
        readonly property bool attached:  Settings.values.islandAttached === true
        // Floating: the gap above the island.
        readonly property int gap:        attached ? 0 : root.px(6)
        // The top band the island takes: what's below it (menus' cards, the OSD at the top, the
        // wallpaper strip, the launcher and editors) starts here, and windows below it.
        readonly property int reserved:   gap + height
        readonly property int openRadius: root.round(32)  // bottom corners when open (closed: half the height)
        // The menus' widths (user's choice, 2026-11-04: each its own, so the island morphs into
        // a shape that fits it): wider for the grids and lists, narrower for the power menu.
        // panelWidth is the rest's (the hover player, notification and attention pop-ups, the
        // lock screen's password field).
        readonly property int panelWidth: root.px(380)
        readonly property var menuWidths: ({
            settings: root.px(460), clipboard: root.px(460), emoji: root.px(460),
            today: root.px(400), media: root.px(400),
            power: root.px(340)
        })
        function menuWidth(name: string): int {
            return menuWidths[name] ?? panelWidth;
        }
        // Height of the island's window. The open island never grows past this; the rest of
        // the window is transparent and lets clicks through.
        readonly property int maxHeight:  root.px(840)
        // How long the workspace dots stay in the time's place after the workspace changes (ms).
        readonly property int workspaceFlash: 1200
        // How long "Reloaded" shows after a shell reload, and a failed reload's error (ms).
        readonly property int reloaded:       2000
        readonly property int reloadError:    10000
        // How long the greeting after an unlock stays (ms; bar/WelcomeCard.qml), and its chips' height.
        readonly property int welcome:        4500
        readonly property int chip:           root.px(32)
    }

    readonly property QtObject tile: QtObject {
        readonly property int height: root.px(64)
        readonly property int round:  root.px(52) // the round on/off buttons under the tiles
    }

    readonly property QtObject slider: QtObject {
        readonly property int height: root.px(44)
    }

    readonly property QtObject wifi: QtObject {
        readonly property int qr: root.px(200) // the "join this network" QR code (WifiPage.qml)
    }

    readonly property QtObject list: QtObject {
        readonly property int rowHeight: root.px(52)
        readonly property int rows:      6  // visible rows in the Wi-Fi / Bluetooth lists
    }

    readonly property QtObject workspace: QtObject {
        readonly property int dot:       root.px(6)  // inactive indicator: a dot
        readonly property int activeDot: root.px(16) // active indicator stretches into a pill
        readonly property int spacing:   root.px(4)  // between the dots
        // Dots always shown, empty or not (Settings; 0 = only the workspaces in use).
        readonly property int minimum: ThemeScale.pick(Settings.values.workspaceDots, ThemeScale.workspaceDots, 5)
        readonly property int menu:      5  // the window menu's "move to workspace" buttons
    }

    // Media in the island: the live activity, the hover player and the media menu.
    readonly property QtObject media: QtObject {
        readonly property int activityArt: root.px(22)   // cover in the closed island
        readonly property int hoverDelay:  250  // ms of hover before the player opens, and of
                                                // absence before it closes again
        readonly property int menuArt:     root.px(160)  // cover in the media menu
    }

    // Desktop widgets (desktop/), a family like iOS's and Android's: a small square, a medium one
    // twice as wide and a large one twice as tall as that, the same corners and padding.
    readonly property QtObject desktop: QtObject {
        // Through text(), not px(): the widgets are mostly text, and grow with its size too.
        // At 100 % from DesktopWidgets.js's `unit`, which lays them out (and is tested) in those px.
        readonly property int size:    root.text(DesktopWidgetsJs.unit.size) // a small widget's side; every widget's height
        readonly property int gap:     root.px(DesktopWidgetsJs.unit.gap)    // between widgets snapped side by side
        readonly property int medium:  size * 2 + gap
        // A widget's size by its name (DesktopWidgets.js's kinds): { w, h }.
        function box(name: string): var {
            const kind = DesktopWidgetsJs.kinds.find(k => k.name === name);
            return { w: kind?.medium ? medium : size, h: kind?.large ? medium : size };
        }
        // How large the widgets are against 100 %: their places zoom by it (DesktopWidgets.js).
        readonly property real zoom:   size / DesktopWidgetsJs.unit.size
        readonly property int padding: root.text(20)
        readonly property int radius:  root.round(28)
        readonly property int margin:  root.px(32)  // from the screen's edges, when snapped
        readonly property int reach:   root.px(24)  // how close a drop snaps
        readonly property int clock:   root.text(64) // the big value: the time, the day, the temperature, the counts
        readonly property int value:   root.text(40) // a big value sharing its card with a list (the hourly weather, the month)
        readonly property int ring:    root.text(80) // the battery and timer widgets' ring
        readonly property int ringWidth: root.px(8)
        readonly property int icon:    root.px(28)  // the weather's sky and the battery's icon
        readonly property int eventBar: root.px(3)  // the accent bar beside a calendar event
        readonly property int copiedFor: 1500        // ms the clipboard widget says "Copied"
        readonly property int scrollMark: root.px(3) // the bar beside a list that scrolls
        readonly property real scrollMarkOpacity: 0.5
        readonly property int wheelLines: 3          // lines one wheel notch scrolls the note
        readonly property int clipboardSettle: 300   // ms for cliphist to store a copy before listing
    }

    readonly property QtObject dock: QtObject {
        // App icons at rest (Settings -> Windows -> Dock), and the bar around them.
        readonly property int icon:      root.px(ThemeScale.pick(Settings.values.dockIconSize, ThemeScale.dockIcons, 44))
        readonly property int height:    icon + root.px(16)
        readonly property int margin:    root.px(8)   // between the bar and the screen edge
        readonly property int radius:    root.round(22)  // the bar's corners
        readonly property int trigger:   3   // the strip at the bottom edge that brings a hidden dock back
        readonly property int hideDelay: 500 // ms the dock stays after the pointer leaves
        readonly property int menuSpace: root.px(240) // room above the dock for tooltips and the menu
        readonly property int menuWidth: root.px(220) // the right-click menu
        readonly property int badge:     root.px(18)  // notification count on an icon
        readonly property int preview:   root.px(130) // window previews on hover: their height
        readonly property int previewDelay: 400 // ms resting on an app before its previews show
    }

    readonly property QtObject switcher: QtObject {
        readonly property int thumbHeight: root.px(220) // window previews in Alt+Tab; widths follow each window's shape
        readonly property real maxAspect:  2.2 // the widest a preview gets, relative to its height
        readonly property int labelHeight: root.px(32)  // app icon and title under each preview
    }

    readonly property QtObject overview: QtObject {
        readonly property int margin:     root.px(48)  // around the window grid
        readonly property int gap:        root.px(24)  // between window previews
        readonly property int label:      root.px(32)  // app icon and title under each preview
        readonly property int workspace:  root.px(168) // width of a workspace in the strip (16:9)
        readonly property int stripSpace: root.px(140) // height of the strip at the bottom
        readonly property int minimized:  root.px(280) // width of the minimized windows' list
    }

    readonly property QtObject snap: QtObject {
        readonly property int width: root.px(56) // one layout picture in the snap picker (16:9)
    }

    readonly property QtObject welcome: QtObject {
        readonly property int width: root.px(440) // the tour's card
        readonly property int icon:  root.px(48)  // the symbol at the top of each card
        readonly property int dot:   root.px(6)   // the progress dots
    }

    readonly property QtObject lock: QtObject {
        readonly property int blur:       64  // the glass behind the island and the widgets
        readonly property int shake:      root.px(12) // how far a wrong password shakes the island
        readonly property int islandAwake: 10000      // ms the island stays open after a key or a pointer move
        readonly property int moved:      24  // px the pointer must move to end the grace period
        readonly property int opening:    root.anim.morph // ms the island shows the lock open before the desktop
    }

    readonly property QtObject polkit: QtObject {
        readonly property int field: root.px(340) // the password prompt's field; its card is a little wider
    }

    readonly property QtObject wallpaper: QtObject {
        readonly property int thumbHeight: root.px(120) // thumbnails in the picker (16:9)
        readonly property int browserThumb: root.px(240)   // the Wallpapers page's pictures' smallest width (16:9)
    }

    readonly property QtObject emoji: QtObject {
        readonly property int cell: root.px(42) // one emoji in the picker's grid
        readonly property int size: root.px(26) // the emoji glyph
        readonly property int rows: 7  // visible rows; the grid scrolls past that
    }

    readonly property QtObject clipboard: QtObject {
        readonly property int height:      root.px(360) // the list scrolls past this
        readonly property int imageHeight: root.px(56)  // image thumbnails
    }

    readonly property QtObject notifications: QtObject {
        readonly property int historyHeight: root.px(300)  // the history in the "today" menu scrolls past this
    }

    readonly property QtObject battery: QtObject {
        readonly property real low: 0.15 // at or below this (and discharging) the battery turns red
        readonly property real warn: 0.20     // a "battery low" notification (services/BatteryAlerts.qml)
        readonly property real critical: 0.10 // a critical one, which stays until dismissed
        // The battery pill in quick settings (controlcenter/BatteryPill.qml).
        readonly property int width:  root.px(22)
        readonly property int height: root.px(11)
        readonly property int radius: root.round(4)
        readonly property int nub:    root.px(3)  // the terminal on the right end
    }

    readonly property QtObject launcher: QtObject {
        // Settings -> Appearance -> Size: its width, and the result rows shown before it scrolls.
        readonly property int width:     root.px(ThemeScale.pick(Settings.values.launcherWidth, ThemeScale.launcherWidths, 560))
        readonly property int rows:      ThemeScale.pick(Settings.values.launcherRows, ThemeScale.launcherRows, 8)
        readonly property int rowHeight: root.px(52)
        // Settings and Wallpapers grown out of it, at the large size (compact is its width).
        readonly property int pageWidth:  root.px(1040)
        readonly property int pageHeight: root.px(680)
    }

    // The on-screen editors (customize/).
    readonly property QtObject editor: QtObject {
        readonly property int slider: root.px(240)    // a slider's width in a sheet
        readonly property int pictureCard: root.px(160) // the desktop editor's pictures
        readonly property int tile: root.px(200)      // an editor tile's height (SheetTile.qml)
        readonly property int fontChip: root.px(56)   // a font's chip, "Aa" over its name
        readonly property int label: root.px(40)      // a short label before a control in a tile
        readonly property int sample: root.px(360) // the windows editor's sample window
    }

    readonly property QtObject settings: QtObject {
        readonly property int sidebar:   root.px(230) // the category list
        readonly property int content:   root.px(600) // the pages' maximum width
        readonly property int rowHeight: root.px(64)
        readonly property int stepper:   root.px(96)  // the value between a stepper's - and +
        readonly property int stepperWide: root.px(170) // a stepper showing a screen mode ("1920 × 1080, 165 Hz")
        readonly property int card:      root.px(124) // a picture card (ChoiceCards.qml), 16:10
        readonly property int screenTimeChart: root.px(120) // the last 7 days' bars, with the day names
        readonly property int screenTimeBar: root.px(28)    // one day's bar at most
    }

    readonly property QtObject osd: QtObject {
        // Close to the closed island's size (user's choice: it looked big next to it).
        readonly property int width:   root.px(240)
        readonly property int height:  root.px(40)
        readonly property int gap:     root.px(64)   // distance from the bottom screen edge, above the dock
        readonly property int gapLow:  root.px(24)   // the same while the dock is hidden
        readonly property int track:   root.px(5)    // height of the level bar
        readonly property int below:   root.px(12)   // under the island, when it's at the top
    }
}
