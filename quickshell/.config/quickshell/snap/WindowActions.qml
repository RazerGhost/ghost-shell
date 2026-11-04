import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "../services/WorkspaceSlots.js" as WorkspaceSlots

// The top of the window menu (WindowMenu.qml): the window's icon and title, what title bar
// buttons would do (minimize, maximize, fullscreen, close), floating or tiling it, tabs, and
// moving it to another workspace.
// The snap layouts come below it.
Column {
    id: root

    // The window the menu acts on: the one focused when the menu opened.
    property HyprlandToplevel target

    // An action ran; the menu closes.
    signal done()

    function act(action: var): void {
        action(target);
        done();
    }

    spacing: Theme.spacing.m

    // A round button with a caption below, like a share sheet's row.
    component Action: Column {
        id: action

        property string icon
        property string text
        signal triggered()

        // Six share the row, which is as wide as the snap layouts below.
        width: Math.min(Theme.tile.height, (root.width - Theme.spacing.xs * 5) / 6)
        spacing: Theme.spacing.xs
        enabled: root.target !== null
        opacity: enabled ? 1 : 0.35

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.slider.height
            height: width
            radius: width / 2
            color: Colors.m3surfaceContainerHighest

            IconButton {
                anchors.fill: parent
                icon: action.icon
                label: action.text
                onClicked: action.triggered()
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: action.text
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
            Accessible.ignored: true
        }
    }

    // The window: app icon, title, app.
    Row {
        width: parent.width
        spacing: Theme.spacing.m

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Theme.icon.launcher
            visible: root.target !== null
            source: visible ? Quickshell.iconPath(Windows.iconFor(root.target), "application-x-executable") : ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.icon.launcher - parent.spacing

            Text {
                width: parent.width
                text: root.target?.title || "No window focused"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.target?.wayland?.appId ?? ""
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                elide: Text.ElideRight
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacing.xs

        Action { icon: "minimize"; text: "Minimize"; onTriggered: root.act(Windows.minimize) }
        Action { icon: "open_in_full"; text: "Maximize"; onTriggered: root.act(Windows.toggleMaximized) }
        Action { icon: "fullscreen"; text: "Fullscreen"; onTriggered: root.act(Windows.toggleFullscreen) }
        Action {
            readonly property bool floating: root.target?.lastIpcObject?.floating ?? false
            icon: floating ? "grid_view" : "picture_in_picture"
            text: floating ? "Tile" : "Float"
            onTriggered: root.act(Snap.toggleFloating)
        }
        Action {
            readonly property bool grouped: (root.target?.lastIpcObject?.grouped ?? []).length > 0
            icon: grouped ? "tab_close" : "tab"
            text: grouped ? "Take out" : "Tabs"
            onTriggered: root.act(Windows.toggleTabs)
        }
        Action { icon: "close"; text: "Close"; onTriggered: root.act(Windows.close) }
    }

    // Move to workspace: one numbered pill per workspace dot; the window's own is filled.
    Column {
        visible: root.target !== null
        width: parent.width
        spacing: Theme.spacing.s

        Text {
            text: "Move to workspace"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }

        Row {
            spacing: Theme.spacing.s

            Repeater {
                model: Theme.workspace.menu

                Rectangle {
                    id: pill

                    required property int index
                    readonly property int workspace: index + 1
                    readonly property bool current: WorkspaceSlots.idOf(root.target?.workspace) === workspace

                    width: Theme.slider.height
                    height: Theme.island.height
                    radius: Theme.radius.full
                    color: current ? Colors.m3primary : Colors.m3surfaceContainerHighest

                    Accessible.role: Accessible.Button
                    Accessible.name: "Move to workspace " + workspace
                    Accessible.onPressAction: root.act(w => Windows.moveToWorkspace(w, pill.workspace))

                    Text {
                        anchors.centerIn: parent
                        text: pill.workspace
                        color: pill.current ? Colors.m3onPrimary : Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: pillArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act(w => Windows.moveToWorkspace(w, pill.workspace))
                    }

                    StateLayer {
                        radius: pill.radius
                        color: pill.current ? Colors.m3onPrimary : Colors.m3onSurface
                        hovered: pillArea.containsMouse
                    }
                }
            }
        }
    }
}
