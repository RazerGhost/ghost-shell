import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import "Fuzzy.js" as Fuzzy

// A launcher result: an app or one of its shortcuts, a window, a file or a command (see
// Launcher.qml's launch()). Its icon, name and a second line saying what it is.
MouseArea {
    id: root

    required property var modelData
    required property int index
    readonly property DesktopEntry entry: modelData.entry ?? null
    readonly property string title: modelData.window ? modelData.window.title
        : modelData.file ? modelData.file.name
        : modelData.command ? modelData.command
        : modelData.action?.name ?? entry?.name ?? ""
    // For a shortcut, the app it belongs to.
    readonly property string subtitle: modelData.window ? "Open window"
        : modelData.file ? modelData.file.folder
        : modelData.command ? "Run in the terminal"
        : modelData.action ? entry.name : entry?.genericName || entry?.comment || ""
    readonly property string icon: modelData.window ? Windows.iconFor(modelData.window)
        : modelData.file ? Fuzzy.fileIcon(modelData.file.name)
        : modelData.command ? "utilities-terminal"
        : entry?.icon ?? ""

    signal activated()

    width: ListView.view.width
    height: Theme.launcher.rowHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: ListView.view.currentIndex = index
    onClicked: activated()

    Accessible.role: Accessible.ListItem
    Accessible.name: subtitle !== "" ? title + ", " + subtitle : title
    Accessible.onPressAction: activated()

    IconImage {
        id: appIcon
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: Theme.icon.launcher
        // Falls back to a generic icon when the theme has no match.
        source: Quickshell.iconPath(root.icon, "application-x-executable")
    }

    Column {
        anchors.left: appIcon.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacing.m
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }
}
