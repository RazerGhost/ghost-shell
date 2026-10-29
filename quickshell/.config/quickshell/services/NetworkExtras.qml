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

    Process {
        id: readConnections
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE", "connection", "show"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.connections = NetworkExtrasJs.connections(text)
        }
    }

    Process {
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
            readConnections.running = true;
            readRadios.running = true;
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
