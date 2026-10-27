// Network state from NetworkManager, shared by the island's status icons and quick settings.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    // These bindings re-run when any property they read changes (a device connecting,
    // the signal strength moving), including reads inside find().
    readonly property list<NetworkDevice> devices: Networking.devices.values
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    // The Wi-Fi card, connected or not; null on machines without one.
    readonly property WifiDevice wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WifiNetwork wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    readonly property string icon: wired ? "lan"
                                 : wifiNetwork ? wifiIcon(wifiNetwork.signalStrength)
                                 : Networking.wifiEnabled ? "wifi_find"
                                 : "signal_wifi_off"
    readonly property string label: wired ? "Wired"
                                  : wifiNetwork ? wifiNetwork.name
                                  : Networking.wifiEnabled ? "Not connected"
                                  : "Off"

    // strength is 0-1. Three arcs, like Android: widgets/WifiIcon.qml draws the unlit ones dimmed.
    function wifiIcon(strength: real): string {
        return strength > 0.66 ? "wifi"
             : strength > 0.33 ? "wifi_2_bar"
             : "wifi_1_bar";
    }
}
