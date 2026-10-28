// The settings window: a normal app window (user's choice, rather than an island menu) with the
// categories on the left and a title bar like the other apps' (maximize and close, the same
// buttons as GTK apps get from the core module's button-layout; Hyprland ignores minimize requests). Opened with Super+I, the gear in quick settings, or
// `qs ipc call settings open` (shell.qml). Choices are saved by services/Settings.qml.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.theme
import qs.widgets

Singleton {
    id: root

    property alias open: persist.open
    property alias page: persist.page

    // Stays open on the same page when the shell reloads (after editing its files).
    PersistentProperties {
        id: persist
        reloadableId: "settingsWindow"

        property bool open: false
        property string page: "nightlight"
    }

    // This window in Hyprland's list, for maximizing. Not FloatingWindow.maximized: Hyprland marks
    // every window as tiled on all edges (so apps drop their shadows), which Qt reports as
    // maximized. Hyprland's own state (fullscreen 1 = maximized) stays fresh because the dock
    // re-reads the window list on every fullscreen change.
    readonly property HyprlandToplevel toplevel: (Hyprland.toplevels?.values ?? [])
        .find(t => t.wayland?.appId === "org.quickshell" && t.title === "Settings") ?? null
    readonly property bool maximized: toplevel?.lastIpcObject?.fullscreen === 1

    function toggleMaximized(): void {
        if (toplevel)
            Windows.toggleMaximized(toplevel);
    }

    readonly property var pages: [
        { id: "nightlight", icon: "nightlight", title: "Night light" },
        { id: "dnd", icon: "do_not_disturb_on", title: "Do Not Disturb" },
        { id: "idle", icon: "bedtime", title: "Idle and power" },
        { id: "input", icon: "touchpad_mouse", title: "Keyboard and touchpad" },
        { id: "windows", icon: "select_window", title: "Windows" },
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

        // The title bar: drag it to move the window, double-click to maximize.
        MouseArea {
            id: titleBar

            width: parent.width
            height: Theme.settings.titleBar
            // The move starts once the pointer has dragged a little, not on the press itself:
            // Hyprland takes over the pointer during a move, which swallowed double-clicks.
            property point pressedAt
            onPressed: mouse => pressedAt = Qt.point(mouse.x, mouse.y)
            onPositionChanged: mouse => {
                if (pressed && Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) > Qt.styleHints.startDragDistance)
                    window.startSystemMove();
            }
            onDoubleClicked: root.toggleMaximized()

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.m * 2
                anchors.verticalCenter: parent.verticalCenter
                text: "Settings"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }

            // The chosen page's name, above it.
            Text {
                x: Theme.settings.sidebar + Theme.spacing.l * 2
                anchors.verticalCenter: parent.verticalCenter
                text: root.pages.find(p => p.id === root.page)?.title ?? ""
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.large
                font.weight: Font.DemiBold
                Accessible.role: Accessible.Heading
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.m
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.xs

                WindowButton {
                    icon: root.maximized ? "filter_none" : "crop_square"
                    label: root.maximized ? "Restore" : "Maximize"
                    onClicked: root.toggleMaximized()
                }

                WindowButton {
                    icon: "close"
                    label: "Close"
                    onClicked: root.open = false
                }
            }
        }

        // The categories.
        Column {
            id: sidebar

            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            width: Theme.settings.sidebar
            leftPadding: Theme.spacing.m
            rightPadding: Theme.spacing.m
            spacing: Theme.spacing.xs

            Accessible.role: Accessible.PageTabList
            Accessible.name: "Settings categories"

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
                        opacity: entry.selected ? 1 : entry.containsMouse ? Theme.state.hover : 0

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
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            contentHeight: pages.implicitHeight + Theme.spacing.l
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: pages

                // Centered when the window is wider than a page (maximized).
                x: Math.max(Theme.spacing.l, (content.width - width) / 2)
                width: Math.min(Theme.settings.content, content.width - Theme.spacing.l * 2)
                spacing: Theme.spacing.l

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

                InputPage {
                    width: parent.width
                    visible: root.page === "input"
                }

                WindowsPage {
                    width: parent.width
                    visible: root.page === "windows"
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
