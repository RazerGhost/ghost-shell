import QtQuick
import qs.services
import qs.theme

// Wi-Fi as signal bars rising from left to right (user's choice for the wide island, like a
// phone's): as many lit as the signal's strength fills (at least one), the rest dimmed like
// WifiIcon's unlit arcs. The bars are the information, so it says what they mean to screen readers.
Row {
    id: root

    property color color: Colors.m3onSurface
    readonly property int lit: Math.max(1, Math.ceil(Math.max(0, NetworkStatus.signal) * Theme.signal.count))

    spacing: Theme.signal.gap
    Accessible.role: Accessible.StaticText
    Accessible.name: "Wi-Fi: " + NetworkStatus.label + ", signal " + root.lit + " of " + Theme.signal.count

    Repeater {
        model: Theme.signal.count

        Rectangle {
            required property int index

            anchors.bottom: parent.bottom
            width: Theme.signal.bar
            height: Theme.signal.height * (index + 1) / Theme.signal.count
            radius: width / 2
            color: root.color
            opacity: index < root.lit ? 1 : 0.45
        }
    }
}
