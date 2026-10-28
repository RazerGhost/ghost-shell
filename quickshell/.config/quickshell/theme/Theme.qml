// Design tokens: spacing, radius, fonts, sizes, animation. Colors live in Colors.qml.
// Components use these instead of hardcoded numbers so the look can be tuned in one place.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int s:  8
        readonly property int m:  12
        readonly property int l:  16
    }

    readonly property QtObject radius: QtObject {
        readonly property int s:    8
        readonly property int m:    12
        readonly property int l:    20
        readonly property int xl:   28
        readonly property int full: 999 // clamped to half the height: a pill
    }

    readonly property QtObject font: QtObject {
        readonly property string sans: "Inter"
        readonly property string mono: "MesloLGS Nerd Font" // error messages
        readonly property string icon: "Material Symbols Rounded"
        readonly property int iconWeight: 300 // Material Symbols line weight (400 is the font's default)

        readonly property int small:  11
        readonly property int normal: 13
        readonly property int large:  16
        readonly property int title:  22
    }

    readonly property QtObject icon: QtObject {
        readonly property int small:    16 // status icons in the closed island
        readonly property int normal:   20 // buttons, tiles, sliders
        readonly property int tray:     18 // tray item images
        readonly property int launcher: 32 // app icons in the launcher list
        readonly property int osd:      22
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast:   150
        readonly property int normal: 250
        readonly property int easing: Easing.OutCubic

        // The island's open/close morph: Material 3's "emphasized decelerate" curve, which
        // starts fast and settles gently. Used with easing.type: Easing.BezierSpline.
        readonly property int morph: 450
        readonly property list<real> emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    }

    // Backgrounds of the island, launcher and OSD; Hyprland blurs what's behind them.
    readonly property real surfaceOpacity: 0.85

    readonly property QtObject island: QtObject {
        readonly property int height:     36  // when closed; also the space reserved at the top
        readonly property int padding:    14  // left/right padding inside the closed island
        // The whole island moves this many px right of the screen's middle: the laptop's webcam
        // sits a pixel right of the panel's exact middle (the user lined it up by eye).
        readonly property int offset:     1
        readonly property int fillet:     14  // radius of the concave joins to the screen edge
        readonly property int openRadius: 32  // bottom corners when open (closed: half the height)
        readonly property int panelWidth: 380 // width of the open menus
        // Height of the island's window. The open island never grows past this; the rest of
        // the window is transparent and lets clicks through.
        readonly property int maxHeight:  840
    }

    readonly property QtObject tile: QtObject {
        readonly property int height: 64
        readonly property int round:  52 // the round on/off buttons under the tiles
    }

    readonly property QtObject slider: QtObject {
        readonly property int height: 44
    }

    readonly property QtObject list: QtObject {
        readonly property int rowHeight: 52
        readonly property int rows:      6  // visible rows in the Wi-Fi / Bluetooth lists
    }

    readonly property QtObject workspace: QtObject {
        readonly property int dot:       6  // inactive indicator: a dot
        readonly property int activeDot: 16 // active indicator stretches into a pill
        readonly property int spacing:   4  // between the dots
        readonly property int minimum:   5  // numbers shown on hover even when those workspaces are empty
        readonly property int number:    28 // a number on hover (WorkspaceNumbers.qml)
    }

    // Media in the island: the live activity, the hover player and the media menu.
    readonly property QtObject media: QtObject {
        readonly property int activityArt: 22   // cover in the closed island
        readonly property int hoverDelay:  250  // ms of hover before the player opens, and of
                                                // absence before it closes again
        readonly property int menuArt:     160  // cover in the media menu
    }

    readonly property QtObject dock: QtObject {
        readonly property int height:    60  // the bar
        readonly property int margin:    8   // between the bar and the screen edge
        readonly property int icon:      44  // app icons at rest
        readonly property int radius:    22  // the bar's corners
        readonly property int trigger:   3   // the strip at the bottom edge that brings a hidden dock back
        readonly property int hideDelay: 500 // ms the dock stays after the pointer leaves
        readonly property int menuSpace: 240 // room above the dock for tooltips and the menu
        readonly property int menuWidth: 220 // the right-click menu
    }

    readonly property QtObject switcher: QtObject {
        readonly property int thumbHeight: 220 // window previews in Alt+Tab; widths follow each window's shape
        readonly property real maxAspect:  2.2 // the widest a preview gets, relative to its height
        readonly property int labelHeight: 32  // app icon and title under each preview
    }

    readonly property QtObject overview: QtObject {
        readonly property int margin:     48  // around the window grid
        readonly property int gap:        24  // between window previews
        readonly property int label:      32  // app icon and title under each preview
        readonly property int workspace:  168 // width of a workspace in the strip (16:9)
        readonly property int stripSpace: 140 // height of the strip at the bottom
    }

    readonly property QtObject snap: QtObject {
        readonly property int width: 56 // one layout picture in the snap picker (16:9)
    }

    readonly property QtObject lock: QtObject {
        readonly property int clock:      112 // the big clock
        readonly property int fieldWidth: 340 // password field
        readonly property int blur:       64  // wallpaper blur radius
    }

    readonly property QtObject wallpaper: QtObject {
        readonly property int thumbHeight: 120 // thumbnails in the picker (16:9)
    }

    readonly property QtObject clipboard: QtObject {
        readonly property int height:      360 // the list scrolls past this
        readonly property int imageHeight: 56  // image thumbnails
    }

    readonly property QtObject notifications: QtObject {
        readonly property int timeout:       5000 // ms a pop-up stays (critical ones stay until dismissed)
        readonly property int historyHeight: 300  // the history in the "today" menu scrolls past this
    }

    readonly property QtObject battery: QtObject {
        readonly property real low: 0.15 // at or below this (and discharging) the battery turns red
        // The battery pill in the island (bar/BatteryPill.qml).
        readonly property int width:  22
        readonly property int height: 11
        readonly property int radius: 4
        readonly property int nub:    3  // the terminal on the right end
    }

    readonly property QtObject launcher: QtObject {
        readonly property int width:     560
        readonly property int rows:      8  // visible result rows; the list scrolls past that
        readonly property int rowHeight: 52
    }

    readonly property QtObject settings: QtObject {
        readonly property int width:     880 // the settings window when it opens
        readonly property int height:    620
        readonly property int titleBar:  52  // the bar at the top: drag to move, maximize, close
        readonly property int sidebar:   230 // the category list
        readonly property int content:   600 // the pages' maximum width
        readonly property int rowHeight: 64
        readonly property int stepper:   96  // the value between a stepper's - and +
    }

    readonly property QtObject osd: QtObject {
        readonly property int width:   280
        readonly property int height:  52
        readonly property int gap:     64   // distance from the bottom screen edge
        readonly property int track:   6    // height of the level bar
        readonly property int timeout: 1500 // ms the popup stays up after the last change
    }
}
