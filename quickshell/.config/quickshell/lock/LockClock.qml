import QtQuick
import qs.services
import qs.theme
import "LockClock.js" as LockClock

// The lock and login screens' clock in the style chosen in Settings -> Lock screen: big (one
// bold line), stacked (hours over minutes, the minutes in the accent color), thin (one light
// line) or analog (a ring with hands). Its size and font follow the same page.
Item {
    id: root

    required property date date

    readonly property string style: LockClock.pick(Settings.values.lockClockStyle, LockClock.styles)
    readonly property int size: Math.round(Theme.lock.clock * LockClock.pick(Settings.values.lockClockSize, LockClock.sizes) / 100)
    readonly property var digits: LockClock.digits(date, Settings.values.clock24Hour)
    readonly property string family: Settings.values.lockClockFont || Theme.font.sans

    implicitWidth: style === "analog" ? analog.width : style === "stacked" ? stacked.width : line.width
    implicitHeight: style === "analog" ? analog.height : style === "stacked" ? stacked.height : line.height

    Accessible.role: Accessible.StaticText
    Accessible.name: digits.hours + ":" + digits.minutes + (digits.suffix ? " " + digits.suffix : "")

    // Big and thin: one line, "14:32" or "2:32 PM".
    Text {
        id: line
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.style === "big" || root.style === "thin"
        text: root.digits.hours + ":" + root.digits.minutes + (root.digits.suffix ? " " + root.digits.suffix : "")
        color: Colors.m3onSurface
        font.family: root.family
        font.pixelSize: root.style === "thin" ? root.size * 1.15 : root.size
        font.weight: root.style === "thin" ? Font.Thin : Font.Bold
        font.features: { "tnum": 1 }
    }

    // Stacked: hours over minutes, set tight; AM/PM small under them.
    Column {
        id: stacked
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.style === "stacked"
        spacing: -root.size * 0.25 // the digits' line height has room above and below

        Repeater {
            model: [root.digits.hours, root.digits.minutes]

            Text {
                required property string modelData
                required property int index
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                color: index === 0 ? Colors.m3onSurface : Colors.m3primary
                font.family: root.family
                font.pixelSize: root.size * 1.1
                font.weight: Font.Black
                font.features: { "tnum": 1 }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.digits.suffix !== ""
            topPadding: root.size * 0.25
            text: root.digits.suffix
            color: Colors.m3onSurfaceVariant
            font.family: root.family
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
        }
    }

    // Analog: a ring with twelve marks and two hands.
    Item {
        id: analog

        readonly property var hands: LockClock.hands(root.date)
        readonly property real radius: width / 2

        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.style === "analog"
        width: root.size * 2
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.surfaceTranslucent
            border.width: Theme.outline.normal
            border.color: Colors.glassEdge
        }

        Repeater {
            model: 12

            // A mark at each hour, longer at 12, 3, 6 and 9.
            Rectangle {
                required property int index
                readonly property bool major: index % 3 === 0
                x: analog.radius - width / 2
                y: analog.radius * 0.1
                width: major ? Theme.outline.strong : Theme.outline.normal
                height: analog.radius * (major ? 0.14 : 0.08)
                radius: width / 2
                color: major ? Colors.m3onSurface : Colors.m3onSurfaceVariant
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: analog.radius - analog.radius * 0.1
                    angle: index * 30
                }
            }
        }

        Repeater {
            model: [
                { angle: analog.hands.hour, length: 0.5, width: Theme.px(8), color: Colors.m3onSurface },
                { angle: analog.hands.minute, length: 0.75, width: Theme.px(5), color: Colors.m3primary }
            ]

            Rectangle {
                required property var modelData
                x: analog.radius - width / 2
                y: analog.radius - height
                width: modelData.width
                height: analog.radius * modelData.length
                radius: width / 2
                color: modelData.color
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: height
                    angle: modelData.angle
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Theme.px(14)
            height: width
            radius: width / 2
            color: Colors.m3primary
        }
    }
}
