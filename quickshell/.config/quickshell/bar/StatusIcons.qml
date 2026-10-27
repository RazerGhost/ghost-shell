import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Small status glyphs on the right of the closed island, like Android's status bar.
// Bluetooth and mute only show up when they have something to say.
Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

    WifiIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: NetworkStatus.icon
        font.pixelSize: Theme.icon.small
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: BluetoothStatus.connected.length > 0
        icon: "bluetooth_connected"
        font.pixelSize: Theme.icon.small
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.muted
        icon: "volume_off"
        font.pixelSize: Theme.icon.small
    }

    BatteryPill {
        visible: Battery.present
    }
}
