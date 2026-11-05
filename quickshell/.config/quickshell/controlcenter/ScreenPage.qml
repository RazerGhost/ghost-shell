import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The Display page of quick settings (the Display tile; named ScreenPage, since Settings has a
// DisplayPage): brightness, the laptop screen's refresh
// rate (its lowest one saves battery, and can be used by itself while on battery), night light
// with its warmth, and with a second screen what goes where, like Windows' Win+P (services/
// Display.qml). Resolution, scale and rotation stay in Settings -> Display.
Column {
    id: root

    signal back()
    signal done() // closes the island (Display settings opens over it)

    spacing: Theme.spacing.s

    PageHeader {
        width: parent.width
        title: "Display"
        hasSwitch: false
        onBack: root.back()
    }

    LevelSlider {
        width: parent.width
        visible: Brightness.level >= 0
        value: Brightness.level
        icon: "brightness_medium"
        label: "Brightness"
        onMoved: value => Brightness.set(value)
    }

    // A label on the left, a control on the right.
    component Line: Item {
        id: line
        property string text
        property string note
        default property alias control: holder.data

        width: root.width
        implicitHeight: Math.max(Theme.list.rowHeight, labels.implicitHeight)

        Column {
            id: labels
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.m
            anchors.right: holder.left
            anchors.rightMargin: Theme.spacing.s
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: line.text
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: line.note !== ""
                text: line.note
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: holder
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Line {
        visible: Display.rates.length > 1
        text: "Refresh rate"
        note: Display.lowered ? "On battery: " + Display.lowest + " Hz for now" : "Lower saves battery, higher is smoother"

        Segmented {
            options: Display.rates.map(hz => ({ value: hz, label: hz + " Hz" }))
            current: Display.chosenRate
            onPicked: v => Display.setRate(v)
        }
    }

    Line {
        visible: Display.rates.length > 1
        text: "Lower on battery"
        note: Display.lowest + " Hz while unplugged"

        Switch {
            label: "Lower refresh rate on battery"
            checked: Settings.values.displayLowRefreshOnBattery === true
            onToggled: Settings.values.displayLowRefreshOnBattery = !checked
        }
    }

    Line {
        text: "Night light"

        Switch {
            label: "Night light"
            checked: NightLight.on
            onToggled: NightLight.toggle()
        }
    }

    // Warmth from 6000 K (barely warm) to 2500 K (very warm): further right is warmer.
    LevelSlider {
        width: parent.width
        value: (6000 - Settings.values.nightLightTemperature) / 3500
        icon: "nightlight"
        label: "Night light warmth"
        onMoved: value => Settings.values.nightLightTemperature = Math.round((6000 - value * 3500) / 100) * 100
    }

    // Only with a second screen; never saved (Display.project).
    SectionHeading {
        visible: Display.hasSecondScreen
        leftPadding: Theme.spacing.m
        topPadding: Theme.spacing.xs
        text: "Second screen"
    }

    Repeater {
        model: Display.hasSecondScreen ? [
            { value: "extend", icon: "splitscreen_right", title: "Extend", subtitle: "One desktop across both" },
            { value: "mirror", icon: "content_copy", title: "Duplicate", subtitle: "The same on both" },
            { value: "external", icon: "desktop_windows", title: "Second screen only", subtitle: "The laptop's screen off" },
            { value: "laptop", icon: "laptop", title: "Laptop screen only", subtitle: "The second screen off" }
        ] : []

        ListRow {
            required property var modelData
            readonly property bool chosen: Display.project === modelData.value

            width: root.width
            icon: modelData.icon
            title: modelData.title
            subtitle: modelData.subtitle
            highlighted: chosen
            trailingIcon: chosen ? "check" : ""
            onActivated: Display.project = modelData.value

            Accessible.role: Accessible.RadioButton
            Accessible.checkable: true
            Accessible.checked: chosen
        }
    }

    ListRow {
        width: root.width
        icon: "settings"
        title: "Display settings"
        subtitle: "Resolution, scale, rotation"
        onActivated: {
            LauncherState.showSettings("display");
            root.done();
        }
    }
}
