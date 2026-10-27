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
        readonly property int full: 999 // clamped to half the height: a pill
    }

    readonly property QtObject font: QtObject {
        readonly property string sans: "Inter"
        readonly property string mono: "MesloLGS Nerd Font"
        readonly property string icon: "Material Symbols Rounded"

        readonly property int small:  11
        readonly property int normal: 13
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast:   150
        readonly property int normal: 250
        readonly property int easing: Easing.OutCubic
    }

    readonly property QtObject bar: QtObject {
        readonly property int height:  36
        readonly property int gap:     8    // distance from the top screen edge
        readonly property real opacity: 0.85 // pill background; Hyprland blurs what's behind it
    }

    readonly property QtObject workspace: QtObject {
        readonly property int dot:       8  // inactive indicator: a dot
        readonly property int activeDot: 24 // active indicator stretches into a pill
    }
}
