import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "Spread.js" as Spread

// Small status glyphs on the right of the closed island, like Android's status bar.
// Bluetooth and mute only show up when they have something to say.
Row {
    id: root

    // The island gives the status icons and the workspace dots the same width; the icons spread
    // out to fill it when the dots are wider (see Spread.js).
    property real fillWidth: 0
    readonly property list<real> itemWidths: children.filter(c => c.visible).map(c => c.implicitWidth)
    readonly property real naturalWidth: Spread.naturalWidth(itemWidths, Theme.spacing.xs)

    anchors.verticalCenter: parent.verticalCenter
    spacing: Spread.spacing(itemWidths, Theme.spacing.xs, fillWidth)

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
