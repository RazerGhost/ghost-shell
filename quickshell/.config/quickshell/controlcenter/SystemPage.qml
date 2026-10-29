import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// System page of quick settings: processor, memory, each graphics card and the disk, with a
// bar for how busy or full each is, and the busiest apps with End task. Updated every 2 s while
// the page is open (SystemStats).
Column {
    id: root

    signal back()

    spacing: Theme.spacing.m

    // One reading: a title and details on one line, and a bar below (hidden for value < 0).
    component StatRow: Column {
        id: row

        property string title
        property string detail
        property real value: -1 // 0-1

        width: parent.width
        spacing: Theme.spacing.xs

        Accessible.role: Accessible.StaticText
        Accessible.name: title + ": " + detail

        Item {
            width: parent.width
            implicitHeight: label.implicitHeight

            Text {
                id: label
                x: Theme.spacing.m
                text: row.title
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.m
                text: row.detail
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                anchors.verticalCenter: label.verticalCenter
            }
        }

        Rectangle {
            x: Theme.spacing.m
            width: parent.width - Theme.spacing.m * 2
            height: Theme.spacing.xs
            radius: height / 2
            visible: row.value >= 0
            color: Colors.m3surfaceContainerHighest

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, row.value))
                height: parent.height
                radius: height / 2
                // Nearly full turns the error color, like a warning light.
                color: row.value > 0.9 ? Colors.m3error : Colors.m3primary

                Behavior on width {
                    NumberAnimation { duration: Theme.anim.normal }
                }
            }
        }
    }

    function percent(value: real): string {
        return Math.round(value * 100) + " %";
    }

    function degrees(value: var): string {
        return value === null ? "" : Math.round(value) + " °C";
    }

    PageHeader {
        width: parent.width
        title: "System"
        hasSwitch: false
        onBack: root.back()
    }

    StatRow {
        title: "Processor"
        detail: [SystemStats.cpuLoad >= 0 ? root.percent(SystemStats.cpuLoad) : "…", root.degrees(SystemStats.cpuTemp)]
            .filter(s => s !== "").join(" · ")
        value: SystemStats.cpuLoad
    }

    StatRow {
        visible: SystemStats.memory !== null
        title: "Memory"
        detail: SystemStats.memory ? SystemStats.amount(SystemStats.memory.used, SystemStats.memory.total) : ""
        value: SystemStats.memory ? SystemStats.memory.used / SystemStats.memory.total : -1
    }

    Repeater {
        model: SystemStats.gpus

        StatRow {
            required property var modelData
            title: modelData.name
            detail: modelData.asleep ? "Asleep (saving power)"
                : [root.percent(modelData.load), root.degrees(modelData.temp),
                   SystemStats.amount(modelData.memory.used, modelData.memory.total)].join(" · ")
            value: modelData.asleep ? -1 : modelData.load
        }
    }

    StatRow {
        visible: SystemStats.disk !== null
        title: "Disk"
        detail: SystemStats.disk ? SystemStats.amount(SystemStats.disk.used, SystemStats.disk.total) : ""
        value: SystemStats.disk ? SystemStats.disk.used / SystemStats.disk.total : -1
    }

    // The busiest apps. End task asks for a second click within 4 s, like the power menu.
    property var armed: null

    Timer {
        id: disarm
        interval: Theme.confirmTimeout
        onTriggered: root.armed = null
    }

    Text {
        visible: SystemStats.apps.length > 0
        x: Theme.spacing.m
        text: "Apps"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
    }

    Column {
        width: parent.width

        // Keyed by name (plain strings), so a row stays the same row while its app stays in the
        // list and a click isn't lost when the numbers refresh every 2 s; it reads the app's
        // current numbers itself.
        Repeater {
            model: ScriptModel { values: SystemStats.apps.map(a => a.name) }

            ListRow {
                id: appRow

                required property string modelData
                readonly property var app: SystemStats.apps.find(a => a.name === modelData) ?? null

                width: parent.width
                hoverEnabled: false
                cursorShape: Qt.ArrowCursor
                icon: "memory"
                appIcon: app?.icon ?? ""
                title: modelData
                subtitle: app ? "CPU " + root.percent(app.cpu) + " · " + SystemStats.size(app.memory) : ""
                trailingSpace: endButton.visible ? endButton.width + Theme.spacing.s : 0

                TextButton {
                    id: endButton
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    visible: appRow.app !== null && !appRow.app.essential
                    text: root.armed === appRow.modelData ? "Click to confirm" : "End task"
                    onClicked: {
                        if (root.armed === appRow.modelData) {
                            root.armed = null;
                            SystemStats.endTask(appRow.app);
                        } else {
                            root.armed = appRow.modelData;
                            disarm.restart();
                        }
                    }
                }
            }
        }
    }
}
