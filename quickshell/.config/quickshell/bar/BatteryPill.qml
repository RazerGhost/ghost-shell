import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Android 16-style battery: a pill that fills up with the charge level, with the percentage
// (and a bolt while charging) written inside it. The text changes color where the fill
// passes under it, so it stays readable at any level.
Item {
    id: root

    readonly property color fillColor: Battery.low ? Colors.m3error
                                     : Battery.charging ? Colors.m3primary
                                     : Colors.m3onSurface

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: body.width + Theme.battery.nub
    implicitHeight: Theme.battery.height

    Accessible.role: Accessible.Indicator
    Accessible.name: "Battery " + Math.round(Battery.level * 100) + "%" + (Battery.charging ? ", charging" : "")

    // The percentage and bolt. Drawn twice: on the empty part in the normal text color, and
    // inside the fill (clipped to it) in the island's background color.
    component Label: Row {
        property color tint

        anchors.centerIn: parent
        spacing: 1

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.charging
            icon: "bolt"
            color: parent.tint
            font.pixelSize: Theme.battery.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Battery.level * 100)
            color: parent.tint
            font.family: Theme.font.sans
            font.pixelSize: Theme.battery.text
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }

    Item {
        id: body

        width: Math.max(Theme.battery.width, empty.implicitWidth + Theme.spacing.xs * 2)
        height: parent.height

        // Empty part of the pill.
        Rectangle {
            anchors.fill: parent
            radius: Theme.battery.radius
            color: root.fillColor
            opacity: 0.3
        }

        Label {
            id: empty
            tint: Colors.m3onSurface
        }

        // The charge: a full-size pill clipped to the level's width, with the second label.
        Item {
            width: parent.width * Math.max(0, Math.min(1, Battery.level))
            height: parent.height
            clip: true

            Behavior on width {
                NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
            }

            Rectangle {
                width: body.width
                height: body.height
                radius: Theme.battery.radius
                color: root.fillColor

                Label {
                    tint: Colors.m3surfaceContainer
                }
            }
        }
    }

    // The terminal on the right end, filled once the battery is full.
    Rectangle {
        anchors.left: body.right
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.battery.nub - 1
        height: parent.height / 2.5
        radius: width
        color: root.fillColor
        opacity: Battery.level >= 0.99 ? 1 : 0.3
    }
}
