import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "WifiQr.js" as WifiQr

// The Wi-Fi page's QR code: the connected network (or the hotspot) for a phone to scan and join
// (WifiQr.js, tested). Its name and password come from NetworkManager, the picture from qrencode
// (the capture module). The text reaches qrencode through its environment, not its command
// line, which other users could see. The picture sits in the private runtime folder and goes
// when the QR closes. Shown only while sharing.
Column {
    id: root

    property string sharing: "" // the network shown
    property string qrFile: ""
    readonly property string qrPath: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-wifi-qr.png"

    // Making the picture failed; the page shows why.
    signal failed(string message)

    function share(name: string): void {
        sharing = name;
        qrFile = "";
        readPassword.running = true;
    }

    function close(): void {
        sharing = "";
        qrFile = "";
        Quickshell.execDetached(["rm", "-f", qrPath]);
    }

    visible: sharing !== ""
    spacing: Theme.spacing.s

    // The name and password of the connection active on the Wi-Fi card, a line each (the
    // password "" for an open network). `-e no`: without it nmcli escapes ":" and "\" as "\:" and
    // "\\", which would end up in the QR code.
    Process {
        id: readPassword
        command: ["sh", "-c", `nmcli -e no -s -g 802-11-wireless.ssid,802-11-wireless-security.psk connection show "$(nmcli -e no -g GENERAL.CONNECTION device show "$1")"`,
                  "sh", NetworkStatus.wifiDevice?.name ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.sharing = lines[0] || root.sharing;
                drawQr.environment = { WIFI_QR: WifiQr.text(root.sharing, lines.slice(1).join("\n")) };
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
                root.failed("Couldn't make the QR code (is qrencode installed?)");
        }
    }

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
        onClicked: root.close()
    }
}
