import QtQuick
import Quickshell.Bluetooth
import qs.theme

// Bluetooth adapter state. Click to turn the adapter on or off.
// (Not named Bluetooth.qml: that would shadow the Bluetooth singleton it reads.)
BarIcon {
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property int connected: adapter?.devices.values.filter(d => d.connected).length ?? 0

    // No adapter (or bluetoothd not running): hide instead of showing a dead icon.
    visible: adapter !== null
    icon: !adapter?.enabled ? "bluetooth_disabled"
        : connected > 0 ? "bluetooth_connected"
        : "bluetooth"
    color: adapter?.enabled ? Colors.m3onSurface : Colors.m3onSurfaceVariant
    label: !adapter?.enabled ? "Bluetooth off"
         : connected > 0 ? "Bluetooth, " + connected + " connected"
         : "Bluetooth on"
    interactive: true
    onClicked: adapter.enabled = !adapter.enabled
}
