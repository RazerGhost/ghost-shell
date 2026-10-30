import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.theme

// The title bar of the shell's own app windows (Settings, Wallpapers), drawn by the window like
// a GTK app's: its title, maximize and close (round buttons); drag it to move the window,
// double-click to maximize. Hyprland ignores minimize requests, so there's no minimize. Anything
// else in the bar (Settings' page name) goes inside it.
MouseArea {
    id: root

    required property QsWindow appWindow
    required property string title

    signal closeRequested()

    // This window in Hyprland's list, for maximizing. Not FloatingWindow.maximized: Hyprland marks
    // every window as tiled on all edges (so apps drop their shadows), which Qt reports as
    // maximized. Hyprland's own state (fullscreen 1 = maximized) stays fresh because the dock
    // re-reads the window list on every fullscreen change.
    readonly property HyprlandToplevel toplevel: (Hyprland.toplevels?.values ?? [])
        .find(t => t.wayland?.appId === "org.quickshell" && t.title === root.title) ?? null
    readonly property bool maximized: toplevel?.lastIpcObject?.fullscreen === 1

    function toggleMaximized(): void {
        if (toplevel)
            Windows.toggleMaximized(toplevel);
    }

    width: parent.width
    height: Theme.settings.titleBar
    // The move starts once the pointer has dragged a little, not on the press itself: Hyprland
    // takes over the pointer during a move, which swallowed double-clicks.
    property point pressedAt
    onPressed: mouse => pressedAt = Qt.point(mouse.x, mouse.y)
    onPositionChanged: mouse => {
        if (pressed && Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) > Qt.styleHints.startDragDistance)
            root.appWindow.startSystemMove();
    }
    onDoubleClicked: toggleMaximized()

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.m * 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
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
            onClicked: root.closeRequested()
        }
    }
}
