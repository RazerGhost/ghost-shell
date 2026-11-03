// "Game mode" (the round button in quick settings): while on, Hyprland's animations, blur and
// shadows are off (settings/HyprlandSettings.qml writes them into shell-settings.lua), pop-ups
// wait in the history like Do Not Disturb (critical ones still show), and the power mode is
// Performance, back to the previous mode when it's turned off; while a low battery holds power
// saver, the power mode stays (PowerModes.js, shared with BatteryAlerts). Kept across shell reloads (else
// a reload would leave Performance on with the button off); off again after a restart, like
// Keep awake.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "PowerModes.js" as PowerModes

Singleton {
    id: root

    property alias on: saved.on
    // The power mode before game mode switched to Performance; -1 if it didn't.
    property alias modeBefore: saved.modeBefore

    PersistentProperties {
        id: saved
        reloadableId: "gameMode"
        property bool on: false
        property int modeBefore: -1
        property bool applied: false // what the power mode was last set for
    }

    // Only a switch from the button: a reload restoring `on` (already applied) changes nothing.
    onOnChanged: {
        if (on === saved.applied)
            return;
        saved.applied = on;
        if (!PowerProfiles.hasPerformanceProfile)
            return;
        const saverHeld = BatteryAlerts.modeBefore !== -1;
        const change = on ? PowerModes.gameOn(PowerProfiles.profile, { held: saverHeld, before: BatteryAlerts.modeBefore },
                                              PowerProfile.Performance)
                          : PowerModes.gameOff(PowerProfiles.profile, modeBefore, saverHeld, PowerProfile.Performance);
        modeBefore = change.before;
        if (change.profile !== null)
            PowerProfiles.profile = change.profile;
    }
}
