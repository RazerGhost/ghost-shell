import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "Fuzzy.js" as Fuzzy

// App launcher: type to fuzzy-search installed apps, arrow keys to pick, Enter to launch,
// Escape or a click outside to close. Toggled with `qs ipc call launcher toggle` (tap Super or Super+Space).
Scope {
    id: root

    property bool open: false

    // A result: an app, or one of its shortcuts ({ entry, action }; action null for the app).
    function launch(result: var): void {
        if (result.action)
            result.action.execute();
        else
            Apps.launch(result.entry);
        open = false;
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    // The default apps, for the keybinds: qs ipc call apps open terminal|browser|fileManager,
    // qs ipc call apps terminal yazi. Here because the Apps singleton only exists once used.
    IpcHandler {
        target: "apps"

        function open(kind: string): void {
            Apps.open(kind);
        }

        // `command` is split on spaces: no quoting.
        function terminal(command: string): void {
            Apps.runInTerminal(command.split(" "));
        }
    }

    PanelWindow {
        id: window

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: root.open

        // No anchors: the compositor centers the surface on the screen.
        implicitWidth: Theme.launcher.width
        implicitHeight: panel.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        // Take the keyboard while open, so typing goes to the search field.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Closes the launcher when you click any other window or surface.
        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: root.open = false
        }

        // Start fresh every time it opens.
        onVisibleChanged: {
            if (visible) {
                search.text = "";
                search.focusInput();
            }
        }

        Surface {
            id: panel

            width: parent.width
            implicitHeight: column.implicitHeight + Theme.spacing.m * 2
            radius: Theme.radius.m * 2

            Column {
                id: column

                anchors.fill: parent
                anchors.margins: Theme.spacing.m
                spacing: Theme.spacing.s

                SearchField {
                    id: search

                    width: parent.width
                    placeholder: "Search apps"
                    fontSize: Theme.font.large

                    // New results: select the best match again.
                    onTextChanged: list.currentIndex = 0
                    onKeyPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Escape:
                            root.open = false;
                            break;
                        case Qt.Key_Down:
                            list.incrementCurrentIndex();
                            break;
                        case Qt.Key_Up:
                            list.decrementCurrentIndex();
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (list.currentItem)
                                root.launch(list.currentItem.modelData);
                            break;
                        default:
                            return; // typing goes to the field
                        }
                        event.accepted = true;
                    }
                }

                ListView {
                    id: list

                    width: parent.width
                    implicitHeight: Math.min(count, Theme.launcher.rows) * Theme.launcher.rowHeight
                    clip: true
                    // Re-filtered on every keystroke; DesktopEntries.applications updates
                    // by itself when apps are installed or removed. Includes the apps' own
                    // shortcuts ("New Private Window").
                    // ScriptModel: results that stay while typing keep their row.
                    model: ScriptModel { values: Fuzzy.results(DesktopEntries.applications.values, search.text) }
                    highlightMoveDuration: Theme.anim.fast
                    boundsBehavior: Flickable.StopAtBounds

                    Accessible.role: Accessible.List

                    highlight: Rectangle {
                        radius: Theme.radius.m
                        color: Colors.m3surfaceContainerHighest
                    }

                    delegate: MouseArea {
                        id: row

                        required property var modelData // { entry, action }
                        required property int index
                        readonly property DesktopEntry entry: modelData.entry

                        width: ListView.view.width
                        height: Theme.launcher.rowHeight
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = index
                        onClicked: root.launch(modelData)

                        Accessible.role: Accessible.ListItem
                        Accessible.name: modelData.action ? modelData.action.name + ", " + entry.name : entry.name
                        Accessible.onPressAction: root.launch(modelData)

                        IconImage {
                            id: appIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacing.s
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Theme.icon.launcher
                            // Falls back to a generic icon when the theme has no match.
                            source: Quickshell.iconPath(row.entry.icon, "application-x-executable")
                        }

                        Column {
                            anchors.left: appIcon.right
                            anchors.right: parent.right
                            anchors.leftMargin: Theme.spacing.m
                            anchors.rightMargin: Theme.spacing.s
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                text: row.modelData.action?.name ?? row.entry.name
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.normal
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                // For a shortcut, the app it belongs to.
                                text: row.modelData.action ? row.entry.name : row.entry.genericName || row.entry.comment
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    visible: list.count === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spacing.s
                    bottomPadding: Theme.spacing.s
                    text: "No apps found"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }
        }
    }
}
