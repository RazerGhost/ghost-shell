import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The battery widget (small), like iOS's batteries widget: a ring that fills with the charge
// around the battery's icon, the percentage, and the time left or until full. The ring turns
// the error color when the battery is low.
WidgetSurface {
    id: widget

    readonly property color tone: Battery.low ? Colors.m3error : Colors.m3primary

    ProgressRing {
        id: ring
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.desktop.ring
        height: width
        value: Battery.level
        color: widget.tone

        MaterialIcon {
            anchors.centerIn: parent
            icon: Battery.icon
            color: widget.tone
            font.pixelSize: Theme.icon.normal * 1.4
        }
    }

    Column {
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(Battery.level * 100) + "%"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Battery.timeLabel || (Battery.charging ? "Charging" : "On battery")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: "Battery " + Math.round(Battery.level * 100) + "%" + (Battery.timeLabel ? ", " + Battery.timeLabel : "")
}
