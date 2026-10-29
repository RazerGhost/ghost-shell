import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "Fuzzy.js" as Fuzzy

// A launcher result: an app or one of its shortcuts, a window, a file or a command (see
// Launcher.qml's launch()). Its icon, name and a second line saying what it is.
MouseArea {
    id: root

    required property var modelData
    required property int index
    readonly property DesktopEntry entry: modelData.entry ?? null
    readonly property string title: modelData.web !== undefined ? "Search the web for \u201c" + modelData.web + "\u201d"
        : modelData.color ? modelData.color
        : modelData.keybind ? modelData.keybind.description
        : modelData.window ? modelData.window.title
        : modelData.file ? modelData.file.name
        : modelData.command ? modelData.command
        : modelData.custom ? modelData.custom.name
        : modelData.action?.name ?? entry?.name ?? ""
    // For a shortcut, the app it belongs to.
    readonly property string subtitle: modelData.web !== undefined ? "DuckDuckGo, in your browser"
        : modelData.color ? "Enter copies the color"
        : modelData.keybind ? modelData.keybind.keys + "  ·  " + modelData.keybind.category
        : modelData.window ? "Open window"
        : modelData.file ? modelData.file.folder
        : modelData.command ? "Run in the terminal"
        : modelData.custom ? modelData.custom.subtitle ?? "Your command: " + modelData.custom.command
        : modelData.action ? entry.name : entry?.genericName || entry?.comment || ""
    readonly property string icon: modelData.web !== undefined ? "system-search"
        : modelData.keybind ? "input-keyboard"
        : modelData.window ? Windows.iconFor(modelData.window)
        : modelData.file ? Fuzzy.fileIcon(modelData.file.name)
        : modelData.command ? "utilities-terminal"
        : modelData.custom ? (modelData.custom.icon || "system-run")
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

    // A color: its swatch instead of an icon.
    Rectangle {
        anchors.fill: appIcon
        visible: !!root.modelData.color
        radius: Theme.radius.m
        color: root.modelData.color || "transparent"
        border.width: Theme.glass.edge
        border.color: Colors.glassEdge
    }

    IconImage {
        id: appIcon
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: Theme.icon.launcher
        visible: !root.modelData.color
        // Falls back to a generic icon when the theme has no match.
        source: Quickshell.iconPath(root.icon, "application-x-executable")
    }

    // An app: star it (first in the list) or hide it from the launcher (Settings -> Default apps
    // shows it again). The star stays while it's a favorite.
    readonly property bool isApp: entry !== null && !modelData.action
    readonly property var favorites: Array.from(Settings.values.launcherFavorites ?? [])
    readonly property bool favorite: isApp && favorites.includes(entry.id)

    Row {
        id: appButtons
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter
        visible: root.isApp && (root.containsMouse || root.favorite)

        IconButton {
            icon: "star"
            color: root.favorite ? Colors.m3primary : Colors.m3onSurfaceVariant
            iconSize: Theme.icon.small
            label: root.favorite ? "Remove from favorites" : "Add to favorites"
            onClicked: Settings.values.launcherFavorites = root.favorite
                ? root.favorites.filter(id => id !== root.entry.id)
                : [...root.favorites, root.entry.id]
        }

        IconButton {
            visible: root.containsMouse
            icon: "visibility_off"
            color: Colors.m3onSurfaceVariant
            iconSize: Theme.icon.small
            label: "Hide from the launcher"
            onClicked: Settings.values.launcherHidden = [...Array.from(Settings.values.launcherHidden ?? []), root.entry.id]
        }
    }

    Column {
        anchors.left: appIcon.right
        anchors.right: appButtons.visible ? appButtons.left : parent.right
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
