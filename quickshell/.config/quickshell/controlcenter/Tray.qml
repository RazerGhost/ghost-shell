import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme
import qs.widgets

// Quick settings' "Background apps" page (the system tray, StatusNotifierItem), opened from its
// bottom row; a page like Wi-Fi's since 2026-11-04 (it was its own island menu): a row per app with
// its icon and name. Click activates the app (and closes quick settings), middle click is its
// secondary action, right click or ⋮ opens its own menu.
Column {
    id: root

    signal back()
    // An app was activated; quick settings closes.
    signal done()

    spacing: Theme.spacing.xs

    PageHeader {
        width: parent.width
        title: "Background apps"
        hasSwitch: false
        onBack: root.back()
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

            width: root.width
            appIcon: trayIcon
            title: name
            subtitle: modelData.tooltipDescription || ""
            trailingSpace: menuButton.visible ? menuButton.width : 0
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

            // The app's own menu, also by right-click.
            IconButton {
                id: menuButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                visible: item.modelData.hasMenu
                icon: "more_vert"
                label: item.name + " menu"
                iconSize: Theme.icon.small
                onClicked: menu.open()
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
