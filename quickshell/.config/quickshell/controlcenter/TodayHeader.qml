import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// The today menu's header: the weekday in the accent over the date, and the weather where you
// are beside it (services/Weather.qml: the sky's icon and the temperature, the sky with today's
// high and low under them, and the town, which a click changes). Without a town, or while
// changing it, a field asks for one under the date (Enter saves, Escape keeps the old one).
Column {
    id: root

    property bool editing: false
    readonly property bool asking: editing || Settings.values.weatherLocation === ""
    readonly property var now: Weather.current

    function save(): void {
        Settings.values.weatherLocation = field.text.trim();
        editing = false;
    }

    spacing: Theme.spacing.s

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        width: parent.width
        height: Math.max(date.implicitHeight, weather.implicitHeight)

        Column {
            id: date
            anchors.left: parent.left
            anchors.right: weather.left
            anchors.rightMargin: Theme.spacing.m
            anchors.verticalCenter: parent.verticalCenter

            Accessible.role: Accessible.Heading
            Accessible.name: day.text + ", " + full.text

            Text {
                id: day
                // English names even with Dutch regional formats (NOTES: the calendar locale).
                text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd").toUpperCase()
                color: Colors.m3primary
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                Accessible.ignored: true
            }

            Text {
                id: full
                width: parent.width
                text: Qt.locale(Qt.uiLanguage).toString(clock.date, "d MMMM")
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Accessible.ignored: true
            }
        }

        // The weather: what it's like now, large; the rest small under it, ending in the town.
        Column {
            id: weather
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.asking

            Row {
                anchors.right: parent.right
                spacing: Theme.spacing.xs

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.now !== null
                    icon: root.now?.icon ?? ""
                    color: Colors.m3primary
                    font.pixelSize: Theme.icon.normal
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.now ? root.now.temperature + "°" : (Weather.error || "Loading…")
                    color: root.now ? Colors.m3onSurface : Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: root.now ? Theme.font.title : Theme.font.small
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }

            Text {
                anchors.right: parent.right
                visible: root.now !== null
                text: root.now ? `${root.now.label}  ↑${root.now.high}° ↓${root.now.low}°` : ""
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }

            // The town; click to change it.
            MouseArea {
                id: townArea
                anchors.right: parent.right
                width: town.implicitWidth + Theme.spacing.s * 2
                height: town.implicitHeight + Theme.spacing.xs
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.editing = true

                Accessible.role: Accessible.Button
                Accessible.name: "Weather location: " + town.text + ", change"
                Accessible.onPressAction: root.editing = true

                // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
                activeFocusOnTab: true
                Keys.onReturnPressed: root.editing = true
                Keys.onEnterPressed: root.editing = true
                Keys.onSpacePressed: root.editing = true

                StateLayer {
                    radius: Theme.radius.s
                    hovered: townArea.containsMouse
                }

                FocusRing {
                    radius: Theme.radius.s
                }

                Text {
                    id: town
                    anchors.centerIn: parent
                    text: Weather.place?.name ?? Settings.values.weatherLocation
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }
            }
        }
    }

    SearchField {
        id: field
        width: parent.width
        height: Theme.slider.height
        visible: root.asking
        placeholder: "Your town, for the weather"
        onVisibleChanged: {
            if (visible) {
                text = Settings.values.weatherLocation;
                focusInput();
            }
        }
        onKeyPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.save();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape && Settings.values.weatherLocation !== "") {
                root.editing = false;
                event.accepted = true;
            }
        }
    }
}
