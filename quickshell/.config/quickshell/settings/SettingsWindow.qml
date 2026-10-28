// The settings window: a normal app window (user's choice, rather than an island menu) with the
// categories on the left. Opened with Super+I, the gear in quick settings, or
// `qs ipc call settings open` (shell.qml). Choices are saved by services/Settings.qml.
pragma Singleton

import QtQuick
import Quickshell
import qs.theme
import qs.widgets

Singleton {
    id: root

    property bool open: false
    property string page: "nightlight"

    readonly property var pages: [
        { id: "nightlight", icon: "nightlight", title: "Night light" },
        { id: "dnd", icon: "do_not_disturb_on", title: "Do Not Disturb" },
        { id: "idle", icon: "bedtime", title: "Idle and power" },
        { id: "lock", icon: "lock", title: "Lock and login screen" },
        { id: "apps", icon: "apps", title: "Default apps" },
        { id: "keybinds", icon: "keyboard", title: "Keybinds" }
    ]

    FloatingWindow {
        id: window

        visible: root.open
        title: "Settings"
        implicitWidth: Theme.settings.width
        implicitHeight: Theme.settings.height
        minimumSize: Qt.size(Theme.settings.sidebar + 400, 400)
        color: Colors.m3surface

        // Closing the window (Super+W, Alt+F4) hides it.
        onVisibleChanged: {
            if (!visible)
                root.open = false;
        }

        // The categories.
        Column {
            id: sidebar

            width: Theme.settings.sidebar
            height: parent.height
            topPadding: Theme.spacing.l
            leftPadding: Theme.spacing.m
            rightPadding: Theme.spacing.m
            spacing: Theme.spacing.xs

            Accessible.role: Accessible.PageTabList
            Accessible.name: "Settings categories"

            Text {
                leftPadding: Theme.spacing.m
                bottomPadding: Theme.spacing.m
                text: "Settings"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.pages

                MouseArea {
                    id: entry

                    required property var modelData
                    readonly property bool selected: root.page === modelData.id

                    width: sidebar.width - sidebar.leftPadding - sidebar.rightPadding
                    height: Theme.list.rowHeight - Theme.spacing.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.page = modelData.id

                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.title
                    Accessible.selected: selected
                    Accessible.onPressAction: root.page = modelData.id

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius.full
                        color: entry.selected ? Colors.m3primaryContainer : Colors.m3onSurface
                        opacity: entry.selected ? 1 : entry.containsMouse ? 0.08 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.anim.fast }
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.l
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.m

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: entry.modelData.icon
                            color: entry.selected ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData.title
                            color: entry.selected ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            font.weight: entry.selected ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        // The chosen page; scrolls when it's taller than the window.
        Flickable {
            id: content

            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            contentHeight: pages.implicitHeight + Theme.spacing.l * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: pages

                x: Theme.spacing.l
                y: Theme.spacing.l
                width: Math.min(Theme.settings.content, content.width - Theme.spacing.l * 2)
                spacing: Theme.spacing.l

                Text {
                    leftPadding: Theme.spacing.l
                    text: root.pages.find(p => p.id === root.page)?.title ?? ""
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.title
                    font.weight: Font.DemiBold
                    Accessible.role: Accessible.Heading
                }

                // Only the chosen page is visible; a Column skips the others.
                NightLightPage {
                    width: parent.width
                    visible: root.page === "nightlight"
                }

                DndPage {
                    width: parent.width
                    visible: root.page === "dnd"
                }

                IdlePage {
                    width: parent.width
                    visible: root.page === "idle"
                }

                LockPage {
                    width: parent.width
                    visible: root.page === "lock"
                }

                AppsPage {
                    width: parent.width
                    visible: root.page === "apps"
                }

                KeybindsPage {
                    width: parent.width
                    visible: root.page === "keybinds"
                }
            }
        }
    }
}
