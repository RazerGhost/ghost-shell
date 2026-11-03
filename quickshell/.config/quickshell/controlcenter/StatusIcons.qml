import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Small status glyphs in quick settings' top row, like Android's status bar (they left the closed
// island on 2026-11-03, user's choice: the island only shows the time and what needs attention,
// IslandAlerts.qml). Airplane mode, a VPN, Bluetooth, waiting updates and mute only show up when
// they have something to say. MaterialIcon hides its glyph
// from screen readers (decorative elsewhere); here the glyph is the information, so each one
// says what it means (`Accessible.ignored: false`).
Row {
    id: root

    // The dock and island editor's Status icons can hide each (and the island's timer).
    readonly property var hidden: Array.from(Settings.values.hiddenStatusIcons ?? [])

    function shows(key: string): bool {
        return !hidden.includes(key);
    }

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

    WifiIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("wifi")
        icon: NetworkStatus.icon
        font.pixelSize: Theme.icon.small
        Accessible.name: "Network: " + NetworkStatus.label
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("airplane") && NetworkExtras.airplane
        icon: "flight"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Airplane mode"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("vpn") && NetworkExtras.activeVpn !== null
        icon: "vpn_key"
        font.pixelSize: Theme.icon.small
        Accessible.name: "VPN: " + (NetworkExtras.activeVpn?.name ?? "")
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("bluetooth") && BluetoothStatus.connected.length > 0
        icon: "bluetooth_connected"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Bluetooth: " + BluetoothStatus.label
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("updates") && Updates.count > 0
        icon: "download"
        font.pixelSize: Theme.icon.small
        Accessible.name: Updates.summary
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("muted") && Audio.muted
        icon: "volume_off"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Sound muted"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }
}
