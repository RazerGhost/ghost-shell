// Network state from NetworkManager, shared by quick settings' status icons and tiles.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // These bindings re-run when any property they read changes (a device connecting,
    // the signal strength moving), including reads inside find().
    readonly property list<NetworkDevice> devices: Networking.devices.values
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    // The Wi-Fi card, connected or not; null on machines without one.
    readonly property WifiDevice wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WifiNetwork wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null
    // The network wants you to sign in first (a hotel's or café's login page): NetworkManager's
    // connectivity check is redirected.
    readonly property bool needsSignIn: Networking.connectivity === NetworkConnectivity.Portal

    // Opens the sign-in page: a plain http page made for this, which the network redirects to its
    // login (https pages can't be redirected).
    function signIn(): void {
        Apps.openPath("http://neverssl.com");
    }

    // While signing in, check again every 10 s, so the hint goes away soon after.
    Timer {
        interval: 10000
        running: root.needsSignIn
        repeat: true
        onTriggered: Networking.checkConnectivity()
    }

    // A network's details fill in a moment after it shows up, hence the defaults.
    readonly property string icon: wired ? "lan"
                                 : wifiNetwork ? wifiIcon(wifiNetwork.signalStrength ?? 0)
                                 : Networking.wifiEnabled ? "wifi_find"
                                 : "signal_wifi_off"
    readonly property string label: wired ? "Wired"
                                  : wifiNetwork ? wifiNetwork.name ?? ""
                                  : Networking.wifiEnabled ? "Not connected"
                                  : "Off"

    // The Wi-Fi signal's strength, 0-1 (widgets/SignalBars.qml); -1 when not on Wi-Fi.
    readonly property real signal: wired || !wifiNetwork ? -1 : (wifiNetwork.signalStrength ?? 0)

    // strength is 0-1. Three arcs, like Android: widgets/WifiIcon.qml draws the unlit ones dimmed.
    function wifiIcon(strength: real): string {
        return strength > 0.66 ? "wifi"
             : strength > 0.33 ? "wifi_2_bar"
             : "wifi_1_bar";
    }
}
