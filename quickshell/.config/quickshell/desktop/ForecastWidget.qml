import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "../services/Weather.js" as WeatherJs

// The hourly weather widget (medium), like iOS's: the temperature and the sky now with today's
// high and low at the top, the next six hours below (services/Weather.qml's `hours`). No town:
// it stays out of the lock screen's way without a locked variant.
WidgetSurface {
    id: widget

    readonly property var now: Weather.current

    medium: true

    Row {
        id: top
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: Theme.spacing.s
        visible: widget.now !== null

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: widget.now?.icon ?? ""
            color: Colors.m3primary
            font.pixelSize: Theme.desktop.icon
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (widget.now?.temperature ?? "") + "°"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.features: { "tnum": 1 }
            font.pixelSize: Theme.desktop.value
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors.right: parent.right
        anchors.left: top.right
        anchors.leftMargin: Theme.spacing.m
        anchors.verticalCenter: top.verticalCenter
        visible: widget.now !== null

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignRight
            text: widget.now?.label ?? ""
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignRight
            text: widget.now ? `↑${widget.now.high}°  ↓${widget.now.low}°` : ""
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }

    // The next hours, evenly across the card: the hour, the sky, the temperature.
    Row {
        anchors.bottom: parent.bottom
        width: parent.width
        visible: Weather.hours.length > 0

        Repeater {
            model: Weather.hours

            Column {
                required property var modelData

                width: parent.width / Math.max(Weather.hours.length, 1)
                spacing: Theme.spacing.xs

                Accessible.role: Accessible.StaticText
                readonly property string label: WeatherJs.hourLabel(modelData.hour, Settings.values.clock24Hour)

                Accessible.name: label + ", " + modelData.temperature + "°"

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    // As the clock shows hours (Settings' 24-hour clock).
                    text: parent.label
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                    font.features: { "tnum": 1 }
                }

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon: parent.modelData.icon
                    color: Colors.m3onSurface
                    font.pixelSize: Theme.icon.normal
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.temperature + "°"
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    font.weight: Font.Medium
                    font.features: { "tnum": 1 }
                }
            }
        }
    }

    // Without a town: where to set one.
    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        visible: widget.now === null

        Text {
            text: "No weather yet"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            text: "Set a town in Weather and clock"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
        }
    }
}
