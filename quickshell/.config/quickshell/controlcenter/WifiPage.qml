import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.services
import qs.theme
import qs.widgets
import "WifiQr.js" as WifiQr

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

    // Sharing the connected network as a QR code a phone can scan to join (WifiQr.js, tested):
    // its password comes from NetworkManager, the picture from qrencode (the capture module).
    // The text reaches qrencode through its environment, not its command line, which other users
    // could see. The picture sits in the private runtime folder and goes when the QR closes.
    property string sharing: ""   // the network shown as a QR code
    property string qrFile: ""
    readonly property string qrPath: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-wifi-qr.png"

    function share(network: WifiNetwork): void {
        sharing = network.name;
        qrFile = "";
        readPassword.running = true;
    }

    function closeShare(): void {
        sharing = "";
        qrFile = "";
        Quickshell.execDetached(["rm", "-f", qrPath]);
    }

    // The password of the connection active on the Wi-Fi card ("" for an open network).
    Process {
        id: readPassword
        command: ["sh", "-c", `nmcli -s -g 802-11-wireless-security.psk connection show "$(nmcli -g GENERAL.CONNECTION device show "$1")"`,
                  "sh", NetworkStatus.wifiDevice?.name ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                drawQr.environment = { WIFI_QR: WifiQr.text(root.sharing, text.trim()) };
                drawQr.running = true;
            }
        }
    }

    Process {
        id: drawQr
        command: ["sh", "-c", `printf %s "$WIFI_QR" | qrencode -s 8 -m 2 -o "$1"`, "sh", root.qrPath]
        onExited: code => {
            if (code === 0)
                root.qrFile = "file://" + root.qrPath + "?" + Date.now();
            else
                root.error = "Couldn't make the QR code (is qrencode installed?)";
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

    // The QR code to join the connected network, above the list.
    Column {
        visible: root.sharing !== ""
        width: parent.width
        spacing: Theme.spacing.s

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Scan to join " + root.sharing
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.wifi.qr
            height: width
            source: root.qrFile
            cache: false
            smooth: false // sharp squares
            fillMode: Image.PreserveAspectFit
            Accessible.role: Accessible.Graphic
            Accessible.name: "QR code to join " + root.sharing
        }

        TextButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Done"
            onClicked: root.closeShare()
        }
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
                    onClicked: root.share(networkRow.modelData)
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
        text: Networking.wifiEnabled ? "Searching for networks…" : "Wi-Fi is off"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
