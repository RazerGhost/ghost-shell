import QtQuick
import qs.services
import qs.theme

// Android 16-style battery: a pill that fills up with the charge level, in the accent color
// while charging and red when low. No text inside: the percentage is beside it in quick
// settings.
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

    Item {
        id: body

        width: Theme.battery.width
        height: parent.height

        // Empty part of the pill.
        Rectangle {
            anchors.fill: parent
            radius: Theme.battery.radius
            color: root.fillColor
            opacity: 0.3
        }

        // The charge: a full-size pill clipped to the level's width.
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
