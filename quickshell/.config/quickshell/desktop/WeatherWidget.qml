import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The weather widget (small): the sky's icon and the temperature at the top, the sky and
// today's high and low, the town at the bottom. Without a town, where to set one.
WidgetSurface {
    id: widget

    readonly property var now: Weather.current
    // On the lock screen: the town is where you live, to anyone at the screen.
    property bool hidesPlace: false

    Row {
        anchors.top: parent.top
        spacing: Theme.spacing.xs
        visible: widget.now !== null

        Text {
            text: (widget.now?.temperature ?? "") + "°"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.desktop.weather
            font.weight: Font.Light
        }
    }

    MaterialIcon {
        anchors.top: parent.top
        anchors.right: parent.right
        visible: widget.now !== null
        icon: widget.now?.icon ?? ""
        color: Colors.m3primary
        font.pixelSize: Theme.desktop.icon
    }

    Column {
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 2

        Text {
            width: parent.width
            text: widget.now ? widget.now.label : "No weather yet"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: widget.now ? `↑${widget.now.high}°  ↓${widget.now.low}°`
                                           : "Set a town in Weather and clock"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            visible: widget.now !== null && !widget.hidesPlace
            text: Weather.place?.name ?? Settings.values.weatherLocation
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }
}
