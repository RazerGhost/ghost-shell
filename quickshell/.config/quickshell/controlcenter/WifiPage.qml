import QtQuick
import Quickshell
import Quickshell.Networking
import qs.services
import qs.theme
import qs.widgets

// Wi-Fi page of quick settings: on/off switch and the networks in range. Click a network to
// connect (or disconnect from the connected one). Secured networks you haven't joined before
// ask for the password first. Below them: the saved VPNs, the hotspot and airplane mode
// (services/NetworkExtras.qml). Sharing a network as a QR code is WifiShare.qml.
Column {
    id: root

    // True while the page is on screen; the card only scans for networks then.
    property bool active

    // Network waiting for a password, and the last one we tried to connect to.
    property WifiNetwork asking: null
    property WifiNetwork connecting: null
    property string error

    signal back()

    function open(network: WifiNetwork): bool {
        return network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe;
    }

    function choose(network: WifiNetwork): void {
        error = "";
        if (network.connected) {
            network.disconnect();
        } else if (network.known || open(network)) {
            connecting = network;
            network.connect();
        } else {
            asking = network;
        }
    }

    function submit(password: string): void {
        connecting = asking;
        asking.connectWithPsk(password);
        asking = null;
    }

    spacing: Theme.spacing.s
    onActiveChanged: {
        if (!active) {
            asking = null;
            error = "";
        }
    }

    // Scanning wakes the radio, so only scan while this page is open.
    Binding {
        target: NetworkStatus.wifiDevice
        property: "scannerEnabled"
        value: true
        when: root.active && NetworkStatus.wifiDevice !== null
    }

    Connections {
        target: root.connecting

        function onConnectionFailed(reason: int): void {
            const network = root.connecting;
            root.connecting = null;
            if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) {
                root.error = "Wrong password";
                root.asking = network;
            } else {
                root.error = "Couldn't connect to " + network.name;
            }
        }

        function onConnectedChanged(): void {
            if (root.connecting?.connected)
                root.connecting = null;
        }
    }

    PageHeader {
        width: parent.width
        title: "Wi-Fi"
        checked: Networking.wifiEnabled
        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        onBack: root.back()
    }

    Text {
        visible: text !== ""
        width: parent.width
        leftPadding: Theme.spacing.s
        text: root.error || NetworkExtras.error
        color: Colors.m3error
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }

    // The QR code to join the connected network or the hotspot, above the list.
    WifiShare {
        id: share
        width: parent.width
        onFailed: message => root.error = message
    }

    // Password prompt, shown instead of the list. It's kept out of the list rows on purpose:
    // the list re-sorts as signal strengths change, which would throw away what you typed.
    Column {
        visible: root.asking !== null
        width: parent.width
        spacing: Theme.spacing.s

        onVisibleChanged: {
            if (visible) {
                password.text = "";
                password.focusInput();
            }
        }

        Text {
            leftPadding: Theme.spacing.s
            text: "Password for " + (root.asking?.name ?? "")
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
        }

        TextField {
            id: password
            width: parent.width
            password: true
            placeholder: "Wi-Fi password"
            onAccepted: {
                if (text !== "")
                    root.submit(text);
            }
        }

        Row {
            anchors.right: parent.right
            spacing: Theme.spacing.s

            TextButton {
                text: "Cancel"
                onClicked: {
                    root.asking = null;
                    root.error = "";
                }
            }

            TextButton {
                text: "Connect"
                filled: true
                enabled: password.text !== ""
                onClicked: root.submit(password.text)
            }
        }
    }

    ListView {
        id: list

        visible: Networking.wifiEnabled && root.asking === null
        width: parent.width
        implicitHeight: Math.min(count, Theme.list.rows) * Theme.list.rowHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Connected first, then saved networks, then by signal strength. Hidden networks
        // (no name) are left out. ScriptModel moves rows as signal strengths change instead of
        // rebuilding the list (which jumped back to the top while scanning).
        model: ScriptModel {
            values: (NetworkStatus.wifiDevice?.networks.values ?? [])
                .filter(n => n.name !== "")
                .sort((a, b) => b.connected - a.connected || b.known - a.known || b.signalStrength - a.signalStrength)
        }

        delegate: ListRow {
            id: networkRow

            required property WifiNetwork modelData

            // `?.`: a network that just disappeared leaves its row for a moment with no network.
            width: ListView.view.width
            icon: NetworkStatus.wifiIcon(modelData?.signalStrength ?? 0)
            title: modelData?.name ?? ""
            subtitle: !modelData ? ""
                    : modelData.connected ? "Connected"
                    : modelData.state === ConnectionState.Connecting ? "Connecting…"
                    : modelData.known ? "Saved"
                    : root.open(modelData) ? "Open"
                    : "Secured"
            trailingIcon: !modelData || root.open(modelData) || modelData.known ? "" : "lock"
            highlighted: modelData?.connected ?? false
            onActivated: root.choose(modelData)

            // Share the connected network as a QR code; forget a saved one.
            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.xs

                IconButton {
                    visible: networkRow.modelData?.connected ?? false
                    icon: "qr_code"
                    label: "Share " + (networkRow.modelData?.name ?? "") + " as a QR code"
                    iconSize: Theme.icon.small
                    onClicked: share.share(networkRow.modelData.name)
                }

                IconButton {
                    visible: networkRow.modelData?.known ?? false
                    icon: "delete"
                    label: "Forget " + (networkRow.modelData?.name ?? "")
                    iconSize: Theme.icon.small
                    onClicked: networkRow.modelData.forget()
                }
            }
        }
    }

    Text {
        visible: !Networking.wifiEnabled || (list.count === 0 && root.asking === null)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacing.m
        bottomPadding: Theme.spacing.m
        // Switched off by the laptop's key or a hardware switch (rfkill's hard block): the switch
        // above can't turn it on, so say so.
        text: Networking.wifiEnabled ? "Searching for networks…"
            : Networking.wifiHardwareEnabled ? "Wi-Fi is off"
            : "Wi-Fi is off with the laptop's key or switch"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }

    // The saved VPNs (click to connect or disconnect), the hotspot and airplane mode.
    Repeater {
        model: NetworkExtras.vpns

        ListRow {
            required property var modelData

            width: root.width
            icon: "vpn_key"
            title: modelData.name
            subtitle: modelData.active ? "Connected" : "VPN"
            highlighted: modelData.active
            onActivated: NetworkExtras.toggleVpn(modelData)
        }
    }

    ListRow {
        width: parent.width
        // Starting a hotspot takes the Wi-Fi card off its network, so it shares a cable
        // connection only.
        enabled: NetworkStatus.wired || NetworkExtras.hotspot
        opacity: enabled ? 1 : Theme.state.disabled
        icon: "wifi_tethering"
        title: "Hotspot"
        subtitle: NetworkExtras.hotspot ? "Sharing the cable connection"
                : NetworkStatus.wired ? "Share the cable connection over Wi-Fi"
                : "Needs a cable connection"
        highlighted: NetworkExtras.hotspot
        onActivated: NetworkExtras.setHotspot(!NetworkExtras.hotspot)

        IconButton {
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            visible: NetworkExtras.hotspot
            icon: "qr_code"
            label: "Share the hotspot as a QR code"
            iconSize: Theme.icon.small
            onClicked: share.share("the hotspot")
        }
    }

    ListRow {
        width: parent.width
        icon: "flight"
        title: "Airplane mode"
        subtitle: NetworkExtras.airplane ? "On: Wi-Fi and Bluetooth are off" : "Off"
        highlighted: NetworkExtras.airplane
        onActivated: NetworkExtras.setAirplane(!NetworkExtras.airplane)
    }
}
