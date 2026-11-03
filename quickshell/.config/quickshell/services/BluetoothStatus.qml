// Bluetooth adapter state, shared by quick settings' status icons and tiles.
// (Not named Bluetooth.qml: that would shadow Quickshell's Bluetooth singleton.)
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    // null when there's no adapter or bluetoothd isn't running.
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool pairing: adapter?.devices.values.some(d => d.pairing) ?? false
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property list<BluetoothDevice> connected: adapter?.devices.values.filter(d => d.connected) ?? []

    readonly property string icon: !enabled ? "bluetooth_disabled"
                                 : connected.length > 0 ? "bluetooth_connected"
                                 : "bluetooth"
    readonly property string label: !enabled ? "Off"
                                  : connected.length === 1 ? connected[0].name
                                  : connected.length > 1 ? connected.length + " devices"
                                  : "On"

    // Pairable only while the Bluetooth page pairs a device. autostart.lua's bt-agent accepts
    // every pairing, so an adapter left pairable would let any device that knows the laptop's
    // address pair without asking.
    function allowPairing(): void {
        if (!adapter)
            return;
        adapter.pairable = true;
        pairableTimeout.restart();
    }

    function stopPairing(): void {
        if (adapter && !pairing)
            adapter.pairable = false;
    }

    onPairingChanged: stopPairing()
    onAdapterChanged: stopPairing() // left pairable from before (BlueZ keeps it)

    // A pair() that never got going (the device went away) doesn't change `pairing`.
    Timer {
        id: pairableTimeout
        interval: 60 * 1000
        onTriggered: root.stopPairing()
    }
}
