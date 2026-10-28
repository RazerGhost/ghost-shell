import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.theme

// Bluetooth page of quick settings: on/off switch and devices. Click a device to connect,
// disconnect, or pair it if it's new. Scans for new devices while the page is open.
Column {
    id: root

    property bool active

    signal back()

    function choose(device: BluetoothDevice): void {
        if (device.pairing) {
            device.cancelPair();
        } else if (device.connected) {
            device.disconnect();
        } else if (device.paired) {
            device.connect();
        } else {
            // BlueZ won't bond while the adapter isn't pairable (it starts out off here).
            BluetoothStatus.adapter.pairable = true;
            device.pair();
        }
    }

    // BlueZ device icon names (freedesktop names) to Material Symbols.
    function iconFor(name: string): string {
        if (name.startsWith("audio-head"))
            return "headphones";
        if (name.startsWith("audio"))
            return "speaker";
        if (name === "input-mouse")
            return "mouse";
        if (name === "input-keyboard")
            return "keyboard";
        if (name === "input-gaming")
            return "sports_esports";
        if (name === "phone")
            return "smartphone";
        if (name === "computer")
            return "computer";
        return "bluetooth";
    }

    spacing: Theme.spacing.s

    // Discovery wakes the radio, so only scan while this page is open.
    Binding {
        target: BluetoothStatus.adapter
        property: "discovering"
        value: true
        when: root.active && BluetoothStatus.enabled
    }

    PageHeader {
        width: parent.width
        title: "Bluetooth"
        checked: BluetoothStatus.enabled
        onToggled: BluetoothStatus.adapter.enabled = !BluetoothStatus.enabled
        onBack: root.back()
    }

    ListView {
        id: list

        visible: BluetoothStatus.enabled
        width: parent.width
        implicitHeight: Math.min(count, Theme.list.rows) * Theme.list.rowHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Connected first, then paired, then by name. Devices without a real name (just an
        // address) are left out unless they're paired. ScriptModel: see WifiPage.
        model: ScriptModel {
            values: (BluetoothStatus.adapter?.devices.values ?? [])
                .filter(d => d.paired || d.deviceName !== "")
                .sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))
        }

        delegate: ListRow {
            id: row

            required property BluetoothDevice modelData

            // `?.`: a device that just disappeared leaves its row for a moment with no device.
            width: ListView.view.width
            icon: root.iconFor(modelData?.icon ?? "")
            title: modelData?.name ?? ""
            subtitle: modelData?.state === BluetoothDeviceState.Connecting ? "Connecting…"
                    : modelData?.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                    : modelData?.pairing ? "Pairing… (click to cancel)"
                    : modelData?.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "% battery" : "")
                    : modelData?.paired ? "Paired"
                    : "Click to pair"
            highlighted: modelData?.connected ?? false
            onActivated: root.choose(modelData)

            // Once paired: trust the device, so it can reconnect by itself later (a mouse waking
            // up), and connect, since pairing doesn't always do that. Trusting only now matters:
            // BlueZ keeps trusted devices forever, so a failed pairing would leave a stale entry.
            Connections {
                target: row.modelData

                function onPairedChanged(): void {
                    if (!row.modelData.paired)
                        return;
                    row.modelData.trusted = true;
                    if (!row.modelData.connected)
                        row.modelData.connect();
                }
            }
        }
    }

    Text {
        visible: !BluetoothStatus.enabled || list.count === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacing.m
        bottomPadding: Theme.spacing.m
        text: BluetoothStatus.enabled ? "Searching for devices…" : "Bluetooth is off"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
