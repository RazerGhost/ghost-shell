import QtQuick
import qs.theme

// A network icon from NetworkStatus. For a weak Wi-Fi signal (wifi_1_bar, wifi_2_bar) the
// full three-arc icon is drawn dimmed behind it, so the unlit arcs stay visible like on
// Android. Any other icon (lan, wifi_off, ...) is drawn as is.
MaterialIcon {
    id: root

    MaterialIcon {
        anchors.fill: parent
        z: -1
        visible: root.icon === "wifi_1_bar" || root.icon === "wifi_2_bar"
        icon: "wifi"
        color: root.color
        opacity: 0.3
        font.pixelSize: root.font.pixelSize
    }
}
