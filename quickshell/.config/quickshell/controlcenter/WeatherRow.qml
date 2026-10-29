import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The weather in the today menu (services/Weather.qml): icon, temperature, sky, today's high and
// low, and the town. Without a town, or after clicking it, a field asks for one (Enter saves,
// Escape keeps the old one).
Item {
    id: root

    property bool editing: false
    readonly property bool asking: editing || Settings.values.weatherLocation === ""

    implicitHeight: Theme.slider.height

    function save(): void {
        Settings.values.weatherLocation = field.text.trim();
        editing = false;
    }

    SearchField {
        id: field
        anchors.fill: parent
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

    // Up to the town: a long sky ("Moderate freezing drizzle") ends in "…" before reaching it.
    Row {
        anchors.left: parent.left
        anchors.right: townArea.left
        anchors.leftMargin: Theme.spacing.xs
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.asking
        spacing: Theme.spacing.s

        MaterialIcon {
            id: weatherIcon
            anchors.verticalCenter: parent.verticalCenter
            visible: Weather.current !== null
            icon: Weather.current?.icon ?? ""
            color: Colors.m3primary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.current
                ? `${Weather.current.temperature}° ${Weather.current.label}  ·  ↑${Weather.current.high}° ↓${Weather.current.low}°`
                : Weather.error || "Loading the weather…"
            color: Weather.current ? Colors.m3onSurface : Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            width: parent.width - (weatherIcon.visible ? weatherIcon.width + parent.spacing : 0)
            elide: Text.ElideRight
        }
    }

    // The town; click to change it.
    MouseArea {
        id: townArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.asking
        width: town.implicitWidth + Theme.spacing.m
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.editing = true

        hoverEnabled: true

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
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.place?.name ?? Settings.values.weatherLocation
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }
}
