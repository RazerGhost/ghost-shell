// "Keep awake" (the quick settings tile): while on, the screen doesn't dim, lock or turn off and
// the laptop doesn't suspend when you stop using it. The island windows hold the inhibitor
// (bar/IslandWindow.qml); idle/Idle.qml respects it like a playing video. Not saved: it's off
// again after a restart.
pragma Singleton

import Quickshell

Singleton {
    property bool on: false
}
