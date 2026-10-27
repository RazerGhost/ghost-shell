// Battery level and charging state from UPower, shared by the island and quick settings.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.theme

Singleton {
    // displayDevice combines all batteries into one, the way desktop environments show it.
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool present: device.isLaptopBattery
    readonly property real level: device.percentage // 0-1
    readonly property bool charging: device.state === UPowerDeviceState.Charging
                                  || device.state === UPowerDeviceState.PendingCharge
                                  || device.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && level <= Theme.battery.low

    // Horizontal Android-style icons: battery_android_frame_1 ... _6, then _full. There's no
    // _0, so an almost empty battery still shows one bar.
    readonly property string icon: charging ? "battery_android_frame_bolt"
                                 : level >= 0.95 ? "battery_android_frame_full"
                                 : "battery_android_frame_" + Math.max(1, Math.floor(level * 7))

    // "3h 20m left", "1h 5m until full", "Fully charged"; empty while UPower is still estimating.
    readonly property string timeLabel: device.state === UPowerDeviceState.FullyCharged ? "Fully charged"
                                      : charging && device.timeToFull > 0 ? duration(device.timeToFull) + " until full"
                                      : !charging && device.timeToEmpty > 0 ? duration(device.timeToEmpty) + " left"
                                      : ""

    function duration(seconds: real): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }
}
