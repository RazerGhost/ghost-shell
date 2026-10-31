// Settings: the launcher's Settings page (user's choice, 2026-10-31: it grows out of the search
// bar; it was a window of its own). Large or full size: the pages in a sidebar, grouped, with a
// search field, beside the chosen page. Compact (the search bar's width): the list first, and a
// page on its own once picked, like a phone's settings; the launcher's Back goes back to the
// list (back()). Opened with Super+I, the gear in quick settings, the launcher's search or
// `qs ipc call settings open|page <id>` (LauncherState). Choices are saved by services/Settings.qml.
import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "SettingsPages.js" as SettingsPages

Item {
    id: root

    // The launcher's compact size: one column, the list or a page.
    property bool compact: false
    // Compact: showing the list (else the chosen page).
    property bool listing: false
    readonly property bool showsList: !compact || listing
    readonly property bool showsPage: !compact || !listing

    readonly property string page: LauncherState.settingsPage
    readonly property var pages: SettingsPages.pages

    function choose(id: string): void {
        LauncherState.settingsPage = id;
        listing = false;
    }

    // The launcher's Back: in compact size from a page to the list (true), else nothing to do.
    function back(): bool {
        if (compact && !listing) {
            listing = true;
            return true;
        }
        return false;
    }

    function focusSearch(): void {
        searchField.focusInput();
    }

    property string search: ""
    // The pages the search finds (all of them without one).
    readonly property var shown: {
        const q = search.trim().toLowerCase();
        return q === "" ? root.pages : SettingsPages.matching(q);
    }

    // The sidebar: search and the pages, scrolling when they're taller than the page. The whole
    // width while it's the compact size's list.
    Flickable {
        id: sidebarView

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.compact ? root.width : Theme.settings.sidebar
        visible: root.showsList
        contentHeight: sidebar.implicitHeight + Theme.spacing.m
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Keys.onPressed: event => root.navigate(event)

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
                        root.choose(root.shown[0].id);
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
                    onClicked: root.choose(modelData.id)

                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.title
                    Accessible.selected: selected
                    Accessible.onPressAction: root.choose(modelData.id)

                    // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.choose(modelData.id)
                    Keys.onEnterPressed: root.choose(modelData.id)
                    Keys.onSpacePressed: root.choose(modelData.id)

                    SectionHeading {
                        id: header
                        visible: entry.firstOfSection
                        leftPadding: Theme.spacing.l
                        topPadding: entry.index === 0 ? Theme.spacing.s : Theme.spacing.m
                        bottomPadding: Theme.spacing.xs
                        text: entry.modelData.section
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

                    // Around the row, under the section's name.
                    FocusRing {
                        control: entry
                        anchors.fill: undefined
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: entry.rowHeight
                        radius: Theme.radius.full
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

    // The arrow keys move between the sidebar's pages and the page's controls, like the
    // island's menus (Tab follows the order they're written in). Keys a control doesn't use
    // reach the sidebar or the page, which hand them on here.
    ArrowNavigation {
        id: navigation
        area: root
    }

    function navigate(event: KeyEvent): void {
        const keys = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down];
        if (keys.includes(event.key) && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            event.accepted = navigation.move(event.key);
    }

    // The chosen page; scrolls when it's taller than the panel.
    Flickable {
        id: content

        Keys.onPressed: event => root.navigate(event)

        anchors.left: root.compact ? parent.left : sidebarView.right
        visible: root.showsPage
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentHeight: pages.implicitHeight + Theme.spacing.l
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Only the chosen page is built (it was all 13, kept up to date while hidden; review
        // 2026-10-29). A page is built anew each time it's chosen.
        Loader {
            id: pages

            // Centered when the panel is wider than a page (full size).
            x: Math.max(Theme.spacing.l, (content.width - width) / 2)
            width: Math.min(Theme.settings.content, content.width - Theme.spacing.l * 2)
            sourceComponent: ({ appearance: appearancePage, display: displayPage, lock: lockPage, sound: soundPage, windows: windowsPage, notifications: notificationsPage, power: powerPage, input: inputPage, snapshots: snapshotsPage, apps: appsPage, screentime: screentimePage, keybinds: keybindsPage, capture: capturePage, clock: clockPage })[root.page] ?? null

            Component { id: appearancePage; AppearancePage {} }
            Component { id: displayPage; DisplayPage {} }
            Component { id: lockPage; LockPage {} }
            Component { id: soundPage; SoundSettingsPage {} }
            Component { id: windowsPage; WindowsPage {} }
            Component { id: notificationsPage; NotificationsPage {} }
            Component { id: powerPage; PowerPage {} }
            Component { id: inputPage; InputPage {} }
            Component { id: snapshotsPage; SnapshotsPage {} }
            Component { id: appsPage; AppsPage {} }
            Component { id: screentimePage; ScreenTimePage {} }
            Component { id: keybindsPage; KeybindsPage {} }
            Component { id: capturePage; CapturePage {} }
            Component { id: clockPage; ClockWeatherPage {} }
        }
    }
}
