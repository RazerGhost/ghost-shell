import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The window menu (Alt+Space, or right-click the island): what title bar buttons would do for
// the focused window (minimize, maximize, float, fullscreen, close), moving it to another
// workspace, and the minimized windows to bring back.
Column {
    id: root

    // The window the menu acts on: the one focused when the menu opened.
    property HyprlandToplevel target

    // An action ran; the island closes the menu.
    signal done()

    function act(action: var): void {
        action(target);
        done();
    }

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.m

    // A round button with a caption below, like a share sheet's row.
    component Action: Column {
        id: action

        property string icon
        property string text
        signal triggered()

        width: Theme.tile.height
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
        width: parent.width - root.leftPadding - root.rightPadding
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
        Action { icon: "picture_in_picture"; text: "Float/tile"; onTriggered: root.act(Windows.toggleFloating) }
        Action { icon: "fullscreen"; text: "Fullscreen"; onTriggered: root.act(Windows.toggleFullscreen) }
        Action { icon: "close"; text: "Close"; onTriggered: root.act(Windows.close) }
    }

    // Move to workspace: one numbered pill per workspace dot; the window's own is filled.
    Column {
        visible: root.target !== null
        width: parent.width - root.leftPadding - root.rightPadding
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
                model: Theme.workspace.minimum

                Rectangle {
                    id: pill

                    required property int index
                    readonly property int workspace: index + 1
                    readonly property bool current: root.target?.workspace?.id === workspace

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
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act(w => Windows.moveToWorkspace(w, pill.workspace))
                    }
                }
            }
        }
    }

    MinimizedList {
        width: parent.width - root.leftPadding - root.rightPadding
        onRestored: root.done()
    }
}
