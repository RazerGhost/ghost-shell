import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import "../services/ScreenTime.js" as ScreenTimeJs

// Screen time: a day's total, the last 7 days as bars (hover one for its time, click it to see
// that day), and the day's apps, most used first (services/ScreenTime.qml counts them).
Column {
    id: root

    readonly property var locale: Qt.locale(Qt.uiLanguage)
    readonly property string today: ScreenTimeJs.day(new Date())
    property string chosen: today
    property string hovered: ""
    readonly property var week: ScreenTimeJs.week(ScreenTime.data, new Date())
    readonly property real weekMax: Math.max(...week.map(d => d.seconds), 1)
    readonly property var apps: ScreenTimeJs.apps(ScreenTime.data, chosen)

    // "Today", "Yesterday" or "Tue 27 Oct".
    function dayName(key: string): string {
        if (key === today)
            return "Today";
        const date = new Date(key + "T12:00:00");
        if (ScreenTimeJs.day(new Date(Date.now() - 86400000)) === key)
            return "Yesterday";
        return locale.toString(date, "ddd d MMM");
    }

    spacing: Theme.spacing.l
    // A new day while the window was open.
    onVisibleChanged: {
        if (visible)
            chosen = today;
    }

    SettingGroup {
        // The headline: the hovered day's total, else the chosen day's.
        Column {
            readonly property string shown: root.hovered || root.chosen

            width: parent.width
            topPadding: Theme.spacing.m
            leftPadding: Theme.spacing.l
            spacing: 2

            Text {
                text: root.dayName(parent.shown)
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }

            Text {
                text: ScreenTimeJs.total(ScreenTime.data, parent.shown) === 0 ? "Nothing yet"
                    : ScreenTimeJs.format(ScreenTimeJs.total(ScreenTime.data, parent.shown))
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }
        }

        // The last 7 days, one bar each, today on the right.
        Row {
            id: bars

            x: Theme.spacing.l
            width: parent.width - Theme.spacing.l * 2
            height: Theme.settings.screenTimeChart
            spacing: 2

            Repeater {
                model: root.week

                Item {
                    id: dayBar

                    required property var modelData
                    readonly property bool isChosen: modelData.day === root.chosen

                    width: (bars.width - bars.spacing * 6) / 7
                    height: bars.height

                    Accessible.role: Accessible.Button
                    Accessible.name: root.dayName(modelData.day) + ": " + ScreenTimeJs.format(modelData.seconds)
                    Accessible.onPressAction: root.chosen = modelData.day

                    // Rounded at the top only: a rounded rectangle with its bottom corners
                    // covered by a square one.
                    Rectangle {
                        id: bar
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: label.top
                        anchors.bottomMargin: Theme.spacing.xs
                        width: Math.min(parent.width - Theme.spacing.s, Theme.settings.screenTimeBar)
                        height: dayBar.modelData.seconds === 0 ? 2
                            : Math.max(4, (parent.height - label.height - Theme.spacing.xs) * dayBar.modelData.seconds / root.weekMax)
                        radius: Math.min(4, height / 2)
                        color: dayBar.modelData.seconds === 0 ? Colors.m3outlineVariant : Colors.m3primary
                        opacity: dayBar.isChosen || mouse.containsMouse ? 1 : 0.55

                        Rectangle {
                            visible: parent.height > 8
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                        }
                    }

                    Text {
                        id: label
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.locale.toString(new Date(dayBar.modelData.day + "T12:00:00"), "ddd")
                        color: dayBar.isChosen ? Colors.m3onSurface : Colors.m3onSurfaceVariant
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.small
                        font.weight: dayBar.isChosen ? Font.DemiBold : Font.Normal
                    }

                    // The whole column, not just the bar, so short bars are easy to hit.
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.chosen = dayBar.modelData.day
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.hovered = dayBar.modelData.day;
                            else if (root.hovered === dayBar.modelData.day)
                                root.hovered = "";
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: Theme.spacing.s
        }
    }

    SettingGroup {
        title: root.dayName(root.chosen)

        Text {
            visible: root.apps.length === 0
            width: parent.width
            padding: Theme.spacing.l
            text: "No apps used this day."
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }

        // Each app: icon, name, its time, and a bar against the most used app's.
        Repeater {
            model: root.apps

            Item {
                id: appRow

                required property var modelData
                readonly property DesktopEntry entry: DesktopEntries.byId(modelData.app)

                width: parent.width
                implicitHeight: Theme.settings.rowHeight

                Accessible.role: Accessible.StaticText
                Accessible.name: name.text + ": " + time.text

                IconImage {
                    id: icon
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.l
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: Theme.icon.launcher
                    source: Quickshell.iconPath(appRow.entry?.icon ?? "", "application-x-executable")
                }

                Text {
                    id: name
                    anchors.left: icon.right
                    anchors.leftMargin: Theme.spacing.m
                    anchors.right: time.left
                    anchors.rightMargin: Theme.spacing.m
                    anchors.bottom: parent.verticalCenter
                    text: appRow.entry?.name ?? appRow.modelData.app
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    elide: Text.ElideRight
                }

                Text {
                    id: time
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing.l
                    anchors.bottom: parent.verticalCenter
                    text: ScreenTimeJs.format(appRow.modelData.seconds)
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                    font.features: { "tnum": 1 }
                }

                Rectangle {
                    anchors.left: name.left
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: Theme.spacing.xs
                    width: Math.max(4, (parent.width - x - Theme.spacing.l) * appRow.modelData.seconds / root.apps[0].seconds)
                    height: 4
                    radius: 2
                    color: Colors.m3primary
                }
            }
        }
    }

    Text {
        width: parent.width
        leftPadding: Theme.spacing.l
        text: "Counts the focused app while you use the computer; stops after 2 minutes without input. Kept for 30 days."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
    }
}
