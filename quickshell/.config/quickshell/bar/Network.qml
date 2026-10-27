import QtQuick
import Quickshell.Networking
import qs.theme

// Connection status from NetworkManager: wired, Wi-Fi with signal strength, or offline.
BarIcon {
    // These bindings re-run when any property they read changes (a device connecting,
    // the signal strength moving), including reads inside find().
    readonly property list<NetworkDevice> devices: Networking.devices.values
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property NetworkDevice wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property WifiNetwork wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: wifiNetwork?.signalStrength ?? 0 // 0-1

    icon: wired ? "lan"
        : wifiNetwork ? (strength > 0.75 ? "signal_wifi_4_bar"
                       : strength > 0.5  ? "network_wifi_3_bar"
                       : strength > 0.25 ? "network_wifi_2_bar"
                       : "network_wifi_1_bar")
        : Networking.wifiEnabled ? "signal_wifi_0_bar"
        : "signal_wifi_off"
    color: wired || wifiNetwork ? Colors.m3onSurface : Colors.m3onSurfaceVariant
    label: wired ? "Wired network"
         : wifiNetwork ? "Wi-Fi " + wifiNetwork.name + ", " + Math.round(strength * 100) + "% signal"
         : "Offline"
}
