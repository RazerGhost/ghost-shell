// VPN, hotspot and airplane mode for the Wi-Fi page (Quickshell.Networking only covers the
// network cards). The saved VPN connections and the hotspot come from nmcli, re-read whenever
// `nmcli monitor` reports a change; airplane mode is rfkill (every radio off), re-read on
// `rfkill event`. Parsing in NetworkExtras.js (tested).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "NetworkExtras.js" as NetworkExtrasJs

Singleton {
    id: root

    property var connections: []
    readonly property var vpns: NetworkExtrasJs.vpns(connections)
    readonly property var activeVpn: vpns.find(c => c.active) ?? null
    readonly property bool hotspot: NetworkExtrasJs.hotspotActive(connections)
    property bool airplane: false
    // What went wrong with the last switch, for the page to show ("" when nothing did).
    property string error: ""

    // A VPN connected or disconnected, from the shell or anywhere else (Proton VPN's app,
    // nmcli); the OSD shows it. Not for the VPN already up when the shell starts.
    signal vpnSwitched(name: string, connected: bool)

    // The VPN quick settings' switch reconnects: the one connected last (Settings' lastVpn),
    // else the first saved one.
    readonly property var lastVpn: vpns.find(c => c.name === Settings.values.lastVpn) ?? vpns[0] ?? null
    onVpnSwitched: (name, connected) => {
        if (connected)
            Settings.values.lastVpn = name;
    }

    // The switch: the connected one off, or the last one back on.
    function switchVpn(): void {
        const vpn = activeVpn ?? lastVpn;
        if (vpn)
            toggleVpn(vpn);
    }

    function toggleVpn(vpn: var): void {
        run(["nmcli", "connection", vpn.active ? "down" : "up", "uuid", vpn.uuid],
            "Couldn't " + (vpn.active ? "disconnect " : "connect ") + vpn.name);
    }

    // The hotspot shares a cable connection over Wi-Fi; NetworkManager picks a password, which
    // the Wi-Fi page shows as a QR code.
    function setHotspot(on: bool): void {
        if (on)
            run(["nmcli", "device", "wifi", "hotspot", "ifname", NetworkStatus.wifiDevice?.name ?? ""], "Couldn't start the hotspot");
        else
            run(["nmcli", "connection", "down", NetworkExtrasJs.hotspotName], "Couldn't stop the hotspot");
    }

    function setAirplane(on: bool): void {
        run(["rfkill", on ? "block" : "unblock", "all"], "Couldn't switch airplane mode");
    }

    // One switch at a time (a second one while the first runs would be lost); its error
    // replaces the last one.
    function run(command: var, failure: string): void {
        if (action.running) {
            error = "Still switching, try again in a moment";
            return;
        }
        error = "";
        action.failure = failure;
        action.command = command;
        action.running = true;
    }

    Process {
        id: action
        property string failure
        onExited: code => {
            if (code !== 0)
                root.error = failure;
            readSoon.restart();
        }
    }

    LatestProcess {
        id: readConnections

        property bool readBefore: false

        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE", "connection", "show"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // A failed read (NetworkManager restarting) prints nothing: keep the last list,
                // or every VPN would seem to disconnect and connect again.
                if (text.trim() === "")
                    return;
                const before = root.activeVpn?.name ?? "";
                root.connections = NetworkExtrasJs.connections(text);
                const after = root.activeVpn?.name ?? "";
                if (readConnections.readBefore && after !== before)
                    root.vpnSwitched(after || before, after !== "");
                readConnections.readBefore = true;
            }
        }
    }

    LatestProcess {
        id: readRadios
        command: ["rfkill", "-n", "-o", "SOFT"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.airplane = NetworkExtrasJs.airplane(text)
        }
    }

    // A connection going up or down prints a few lines at once (and rfkill a line per radio):
    // read again once after them.
    Timer {
        id: readSoon
        interval: 300
        onTriggered: {
            readConnections.start();
            readRadios.start();
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: readSoon.restart()
        }
    }

    Process {
        command: ["rfkill", "event"]
        running: true
        stdout: SplitParser {
            onRead: readSoon.restart()
        }
    }
}
