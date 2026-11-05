import QtQuick
import Quickshell
import qs.services
import qs.theme

// VPN page of quick settings (the VPN tile): the switch connects the VPN used last or
// disconnects the connected one; below, every saved VPN (NetworkManager's: Proton VPN's
// WireGuard ones, OpenVPN...). They're also on the Wi-Fi page.
Column {
    id: root

    signal back()
    signal done() // closes the island (an app opens)

    // Proton VPN's app (the proton module), if it's installed: it makes its connection while
    // connected and removes it after, so its servers are picked there.
    readonly property DesktopEntry proton: {
        DesktopEntries.applications.values; // looked up again once the list has filled in (NOTES)
        return DesktopEntries.byId("proton.vpn.app.gtk");
    }

    spacing: Theme.spacing.s

    PageHeader {
        width: parent.width
        title: "VPN"
        hasSwitch: NetworkExtras.vpns.length > 0
        checked: NetworkExtras.activeVpn !== null
        onToggled: NetworkExtras.switchVpn()
        onBack: root.back()
    }

    VpnList {
        width: root.width
    }

    ListRow {
        visible: root.proton !== null
        width: root.width
        appIcon: root.proton?.icon ?? ""
        title: "Open Proton VPN"
        subtitle: "Pick a server or country there"
        onActivated: {
            Apps.launch(root.proton);
            root.done();
        }
    }

    Text {
        visible: NetworkExtras.vpns.length === 0
        width: root.width
        leftPadding: Theme.spacing.m
        rightPadding: Theme.spacing.m
        text: root.proton ? "Proton VPN's connection shows here while it's connected. Other VPNs come from NetworkManager (nm-connection-editor)."
                          : "No VPNs yet. They come from NetworkManager (nm-connection-editor) or a VPN app."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.WordWrap
    }

    Text {
        visible: NetworkExtras.error !== ""
        width: root.width
        leftPadding: Theme.spacing.m
        text: NetworkExtras.error
        color: Colors.m3error
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.WordWrap
    }
}
