import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme

// The "Background apps" menu (system tray, StatusNotifierItem), opened by the arrow next to the
// island's status icons (user's choice 2026-10-29, after chips in quick settings looked
// cluttered): a row per app with its icon and name. Click activates the app (and closes the
// menu), middle click is its secondary action, right click opens its own menu.
Column {
    id: root

    // An app was activated; the island closes the menu.
    signal done()

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.xs

    Text {
        leftPadding: Theme.spacing.s
        bottomPadding: Theme.spacing.xs
        text: "Running in the background"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
    }

    Repeater {
        model: SystemTray.items

        ListRow {
            id: item

            required property SystemTrayItem modelData
            // The tray's icon, unless it names one no icon theme has (KDE Connect asks for Plasma's
            // "kdeconnectindicatordark"): then the app's own icon, or a generic one.
            readonly property string themeIcon: modelData.icon.startsWith("image://icon/") && !modelData.icon.includes("?path=")
                ? modelData.icon.slice("image://icon/".length) : ""
            readonly property string trayIcon: themeIcon !== "" && Quickshell.iconPath(themeIcon, true) === ""
                ? Quickshell.iconPath((DesktopEntries.heuristicLookup(name)
                    ?? DesktopEntries.applications.values.find(e => e.name === name))?.icon ?? "", "application-x-executable")
                : modelData.icon

            // The app's own name from its .desktop file, found by the tray title ("spotify" ->
            // "Spotify"). Not by the id: the fuzzy lookup matched Vesktop's
            // "vesktop_status_icon_1" to Pinentry. Without a title, the tooltip ("Vesktop").
            readonly property string name: (modelData.title ? DesktopEntries.heuristicLookup(modelData.title)?.name : "")
                || modelData.title || modelData.tooltipTitle || modelData.id

            // The button of the click being handled (ListRow only says it was activated).
            property int button: Qt.LeftButton

            width: root.width - root.leftPadding - root.rightPadding
            appIcon: trayIcon
            title: name
            subtitle: modelData.tooltipDescription || (modelData.hasMenu ? "Right-click for its menu" : "")
            trailingIcon: modelData.hasMenu ? "more_vert" : ""
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: event => button = event.button

            onActivated: {
                const pressed = button;
                button = Qt.LeftButton;
                // Some apps only have a menu (onlyMenu); open it on any click for those.
                if (pressed === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (pressed === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu)
                        menu.open();
                } else {
                    modelData.activate();
                    root.done();
                }
            }

            // Opens the item's menu (exported over D-Bus by the app) just below the row.
            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.item: item
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
            }
        }
    }
}
