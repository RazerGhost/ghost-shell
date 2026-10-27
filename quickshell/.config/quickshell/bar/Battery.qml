import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.widgets

// Battery level and charging state. Hidden on machines without a laptop battery.
Row {
    id: root

    // displayDevice combines all batteries into one, the way desktop environments show it.
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property real level: battery.percentage // 0-1
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
                                  || battery.state === UPowerDeviceState.PendingCharge
                                  || battery.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && level <= Theme.battery.low

    visible: battery.isLaptopBattery
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

    Accessible.role: Accessible.StaticText
    Accessible.name: "Battery " + Math.round(level * 100) + "%" + (charging ? ", charging" : "")

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        // battery_0_bar ... battery_6_bar, then battery_full.
        icon: root.charging ? "battery_charging_full"
            : root.level >= 0.95 ? "battery_full"
            : "battery_" + Math.floor(root.level * 7) + "_bar"
        color: root.low ? Colors.m3error : Colors.m3onSurface
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.level * 100) + "%"
        color: root.low ? Colors.m3error : Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        Accessible.ignored: true
    }
}
