// The screens: which is the main one (Settings -> Display; with one screen, that one). The
// desktop widgets and the lock screen's widgets show there, and the dock (or on every screen,
// `dockEverywhere`); notifications and menus open on the screen you're working on.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Your choice while it's connected, else the laptop's own screen, else the first.
    readonly property ShellScreen main: Quickshell.screens.find(s => s.name === Settings.values.mainScreen)
        ?? Quickshell.screens.find(s => /^(eDP|LVDS)/.test(s.name))
        ?? Quickshell.screens[0] ?? null
    readonly property bool several: Quickshell.screens.length > 1
    // The screens the dock shows on.
    readonly property var dockScreens: Settings.values.dockEverywhere === true ? Quickshell.screens : (main ? [main] : [])
}
