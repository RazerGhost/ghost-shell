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
        property string page: "appearance"
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

    // The pages in their sidebar sections (user's choice: grouped, with a search field). The
    // search matches a page's title and these words, so it finds the page for any setting on it.
    readonly property var pages: [
        { id: "appearance", section: "Personalize", icon: "palette", title: "Appearance",
          words: "wallpaper colors theme glass blur style frost acrylic transparent see-through border corners rounding" },
        { id: "display", section: "Personalize", icon: "brightness_6", title: "Display",
          words: "night light warm blue light schedule screen monitor resolution refresh rate hz scale rotation rotate vrr adaptive sync" },
        { id: "lock", section: "Personalize", icon: "lock", title: "Lock screen",
          words: "login greeter picture blur darken clock date name power buttons media music notifications count privacy" },
        { id: "sound", section: "System", icon: "volume_up", title: "Sound",
          words: "equalizer audio bass treble mids voice speakers headphones preset eq sound events chime notification charger usb plug volume screenshot shutter battery" },
        { id: "windows", section: "System", icon: "select_window", title: "Windows",
          words: "gaps tiling hot corner overview reopen floating position wobble wobbly jelly" },
        { id: "notifications", section: "System", icon: "notifications", title: "Notifications",
          words: "do not disturb dnd quiet schedule" },
        { id: "power", section: "System", icon: "battery_charging_full", title: "Power",
          words: "idle dim lock screen off suspend sleep battery plugged low power saver warning" },
        { id: "input", section: "System", icon: "touchpad_mouse", title: "Keyboard and mouse",
          words: "keyboard layout language touchpad natural scrolling tap click pointer speed mouse off" },
        { id: "snapshots", section: "System", icon: "history", title: "Snapshots",
          words: "backup restore btrfs snapper undo files home" },
        { id: "apps", section: "Apps", icon: "apps", title: "Default apps",
          words: "terminal browser file manager editor image viewer video audio player" },
        { id: "screentime", section: "Apps", icon: "hourglass", title: "Screen time",
          words: "usage time apps today week hours digital wellbeing" },
        { id: "keybinds", section: "Apps", icon: "keyboard", title: "Keybinds",
          words: "shortcuts keys welcome tour help" },
        { id: "clock", section: "Apps", icon: "partly_cloudy_day", title: "Weather and clock",
          words: "weather town location 24-hour 12-hour time" }
    ]
    property string search: ""
    // The pages the search finds (all of them without one).
    readonly property var shown: {
        const q = search.trim().toLowerCase();
        return q === "" ? root.pages : root.pages.filter(p => (p.title + " " + p.words).toLowerCase().includes(q));
    }

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
            else
                searchField.focusInput(); // type to search right away
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

        // The sidebar: search and the pages, scrolling when the window is short.
        Flickable {
            id: sidebarView

            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            width: Theme.settings.sidebar
            contentHeight: sidebar.implicitHeight + Theme.spacing.m
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: sidebar

                width: parent.width
                leftPadding: Theme.spacing.m
                rightPadding: Theme.spacing.m
                spacing: Theme.spacing.xs

                Accessible.role: Accessible.PageTabList
                Accessible.name: "Settings categories"

                SearchField {
                    id: searchField
                    width: sidebar.width - sidebar.leftPadding - sidebar.rightPadding
                    placeholder: "Search settings"
                    onTextChanged: root.search = text
                    // Enter opens the first page found.
                    onKeyPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.shown.length > 0) {
                            root.page = root.shown[0].id;
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    visible: root.shown.length === 0
                    leftPadding: Theme.spacing.l
                    topPadding: Theme.spacing.s
                    text: "Nothing found"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }

                Repeater {
                    model: root.shown

                    MouseArea {
                        id: entry

                        required property var modelData
                        required property int index
                        readonly property bool selected: root.page === modelData.id
                        // A section's name above its first page (not while searching).
                        readonly property bool firstOfSection: root.search === ""
                            && (index === 0 || root.shown[index - 1].section !== modelData.section)
                        readonly property real rowHeight: Theme.list.rowHeight - Theme.spacing.s

                        width: sidebar.width - sidebar.leftPadding - sidebar.rightPadding
                        height: rowHeight + (firstOfSection ? header.height : 0)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = modelData.id

                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.title
                        Accessible.selected: selected
                        Accessible.onPressAction: root.page = modelData.id

                        Text {
                            id: header
                            visible: entry.firstOfSection
                            leftPadding: Theme.spacing.l
                            topPadding: entry.index === 0 ? Theme.spacing.s : Theme.spacing.m
                            bottomPadding: Theme.spacing.xs
                            text: entry.modelData.section
                            color: Colors.m3primary
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.small
                            font.weight: Font.DemiBold
                            Accessible.role: Accessible.Heading
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: entry.rowHeight
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
                            anchors.bottom: parent.bottom
                            height: entry.rowHeight
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
        }

        // The chosen page; scrolls when it's taller than the window.
        Flickable {
            id: content

            anchors.left: sidebarView.right
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
                AppearancePage {
                    width: parent.width
                    visible: root.page === "appearance"
                }

                DisplayPage {
                    width: parent.width
                    visible: root.page === "display"
                }

                LockPage {
                    width: parent.width
                    visible: root.page === "lock"
                }

                SoundSettingsPage {
                    width: parent.width
                    visible: root.page === "sound"
                }

                WindowsPage {
                    width: parent.width
                    visible: root.page === "windows"
                }

                NotificationsPage {
                    width: parent.width
                    visible: root.page === "notifications"
                }

                PowerPage {
                    width: parent.width
                    visible: root.page === "power"
                }

                InputPage {
                    width: parent.width
                    visible: root.page === "input"
                }

                SnapshotsPage {
                    width: parent.width
                    visible: root.page === "snapshots"
                }

                AppsPage {
                    width: parent.width
                    visible: root.page === "apps"
                }

                ScreenTimePage {
                    width: parent.width
                    visible: root.page === "screentime"
                }

                KeybindsPage {
                    width: parent.width
                    visible: root.page === "keybinds"
                }

                ClockWeatherPage {
                    width: parent.width
                    visible: root.page === "clock"
                }
            }
        }
    }
}
