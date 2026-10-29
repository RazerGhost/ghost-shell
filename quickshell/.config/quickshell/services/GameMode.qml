// "Game mode" (the round button in quick settings): while on, Hyprland's animations, blur and
// shadows are off (settings/HyprlandSettings.qml writes them into shell-settings.lua), pop-ups
// wait in the history like Do Not Disturb (critical ones still show), and the power mode is
// Performance, back to the previous mode when it's turned off. Not saved: it's off again after
// a restart, like Keep awake.
pragma Singleton

import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool on: false
    // The power mode before game mode switched to Performance; -1 if it didn't.
    property int modeBefore: -1

    onOnChanged: {
        if (on && PowerProfiles.hasPerformanceProfile && PowerProfiles.profile !== PowerProfile.Performance) {
            modeBefore = PowerProfiles.profile;
            PowerProfiles.profile = PowerProfile.Performance;
        } else if (!on && modeBefore !== -1) {
            PowerProfiles.profile = modeBefore;
            modeBefore = -1;
        }
    }
}
