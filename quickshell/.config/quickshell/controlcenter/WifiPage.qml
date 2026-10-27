import QtQuick
import Quickshell.Networking
import qs.services
import qs.theme
import qs.widgets

// Wi-Fi page of quick settings: on/off switch and the networks in range. Click a network to
// connect (or disconnect from the connected one). Secured networks you haven't joined before
// ask for the password first.
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
        visible: root.error !== ""
        width: parent.width
        leftPadding: Theme.spacing.s
        text: root.error
        color: Colors.m3error
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
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
                password.forceActiveFocus();
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

        Rectangle {
            width: parent.width
            implicitHeight: Theme.slider.height
            radius: Theme.radius.full
            color: Colors.m3surfaceContainerHighest

            TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.l
                anchors.rightMargin: Theme.spacing.l
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Colors.m3onSurface
                selectionColor: Colors.m3primary
                selectedTextColor: Colors.m3onPrimary
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                clip: true

                Accessible.role: Accessible.EditableText
                Accessible.name: "Wi-Fi password"
                Accessible.passwordEdit: true

                onAccepted: {
                    if (text !== "")
                        root.submit(text);
                }
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
        // (no name) are left out.
        model: (NetworkStatus.wifiDevice?.networks.values ?? [])
            .filter(n => n.name !== "")
            .sort((a, b) => b.connected - a.connected || b.known - a.known || b.signalStrength - a.signalStrength)

        delegate: ListRow {
            required property WifiNetwork modelData

            width: ListView.view.width
            icon: NetworkStatus.wifiIcon(modelData.signalStrength)
            title: modelData.name
            subtitle: modelData.connected ? "Connected"
                    : modelData.state === ConnectionState.Connecting ? "Connecting…"
                    : modelData.known ? "Saved"
                    : root.open(modelData) ? "Open"
                    : "Secured"
            trailingIcon: root.open(modelData) || modelData.known ? "" : "lock"
            highlighted: modelData.connected
            onActivated: root.choose(modelData)
        }
    }

    Text {
        visible: !Networking.wifiEnabled || (list.count === 0 && root.asking === null)
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacing.m
        bottomPadding: Theme.spacing.m
        text: Networking.wifiEnabled ? "Searching for networks…" : "Wi-Fi is off"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
