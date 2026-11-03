// Low battery warnings, like a phone: a notification at Theme.battery.warn (20 %) and a critical
// one at Theme.battery.critical (10 %), each once per discharge (BatteryAlerts.js, tested). With
// Settings' batterySaver on, the first warning also switches to power saver, and plugging in
// switches back to the mode you had.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.theme
import "BatteryAlerts.js" as BatteryAlertsJs
import "PowerModes.js" as PowerModes

Singleton {
    id: root

    // The most serious warning given since the battery last charged.
    property alias given: persist.given
    // The power mode before power saver was switched on for a low battery; -1 if it wasn't.
    property alias modeBefore: persist.modeBefore

    // Through a shell reload: otherwise the warning came again and plugging in didn't switch
    // power saver back off.
    PersistentProperties {
        id: persist
        reloadableId: "batteryAlerts"

        property string given: ""
        property int modeBefore: -1
    }

    function check(): void {
        if (!Battery.present)
            return;
        if (Battery.charging) {
            given = "";
            // Your mode back, or Performance while game mode is still on (PowerModes.js).
            const back = PowerModes.pluggedIn(modeBefore, GameMode.on && PowerProfiles.hasPerformanceProfile,
                                              PowerProfile.Performance);
            modeBefore = back.before;
            if (back.profile !== null)
                PowerProfiles.profile = back.profile;
            return;
        }
        const warning = BatteryAlertsJs.warning(Battery.level, false, given, Theme.battery.warn, Theme.battery.critical);
        if (warning === "")
            return;
        given = warning;
        const percent = Math.round(Battery.level * 100) + " %";
        const time = Battery.timeLabel ? " · " + Battery.timeLabel : "";
        let body = warning === "critical" ? "Plug in soon: the laptop will suspend when it runs out." : "Plug in to keep going.";
        if (warning === "low" && Settings.values.batterySaver && PowerProfiles.profile !== PowerProfile.PowerSaver) {
            // The mode from before game mode while it's on, so neither undoes the other.
            const low = PowerModes.lowBattery(PowerProfiles.profile, { on: GameMode.on, before: GameMode.modeBefore },
                                              PowerProfile.PowerSaver);
            modeBefore = low.before;
            PowerProfiles.profile = low.profile;
            body += " Power saver is on until you plug in.";
        }
        // Its own sound (the low battery switch), not the notification chime.
        Sounds.play("battery", "dialog-warning");
        Notifications.send("Battery", "battery-caution",
                           (warning === "critical" ? "Battery very low: " : "Battery low: ") + percent + time, body,
                           warning === "critical", ["boolean:suppress-sound:true"]);
    }

    Connections {
        target: Battery

        function onLevelChanged(): void {
            root.check();
        }

        function onChargingChanged(): void {
            root.check();
        }
    }

    Component.onCompleted: check()
}
