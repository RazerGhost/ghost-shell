import QtQuick
import qs.services

// The saved VPNs as rows (click to connect or disconnect; services/NetworkExtras.qml): on the
// Wi-Fi page and the VPN page.
Column {
    id: root

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
}
