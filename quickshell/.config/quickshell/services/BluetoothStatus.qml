// Bluetooth adapter state, shared by the island's status icons and quick settings.
// (Not named Bluetooth.qml: that would shadow Quickshell's Bluetooth singleton.)
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    // null when there's no adapter or bluetoothd isn't running.
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property list<BluetoothDevice> connected: adapter?.devices.values.filter(d => d.connected) ?? []

    readonly property string icon: !enabled ? "bluetooth_disabled"
                                 : connected.length > 0 ? "bluetooth_connected"
                                 : "bluetooth"
    readonly property string label: !enabled ? "Off"
                                  : connected.length === 1 ? connected[0].name
                                  : connected.length > 1 ? connected.length + " devices"
                                  : "On"
}
