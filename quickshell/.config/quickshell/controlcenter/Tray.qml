import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.theme

// System tray (StatusNotifierItem), the apps running in the background: a chip per app with its
// icon and name (user's choice: its own row in quick settings, not small icons next to the
// battery). Left click activates, middle click is the secondary action, right click opens the
// app's menu. Wraps onto more lines when there are many.
Flow {
    spacing: Theme.spacing.s

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: item

            required property SystemTrayItem modelData
            // The tray's icon, unless it names one no icon theme has (KDE Connect asks for Plasma's
            // "kdeconnectindicatordark"): then the app's own icon, or a generic one.
            readonly property string themeIcon: modelData.icon.startsWith("image://icon/") && !modelData.icon.includes("?path=")
                ? modelData.icon.slice("image://icon/".length) : ""
            readonly property string icon: themeIcon !== "" && Quickshell.iconPath(themeIcon, true) === ""
                ? Quickshell.iconPath((DesktopEntries.heuristicLookup(name)
                    ?? DesktopEntries.applications.values.find(e => e.name === name))?.icon ?? "", "application-x-executable")
                : modelData.icon

            // The app's own name from its .desktop file, found by the tray title ("spotify" ->
            // "Spotify"). Not by the id: the fuzzy lookup matched Vesktop's
            // "vesktop_status_icon_1" to Pinentry. Without a title, the tooltip ("Vesktop").
            readonly property string name: (modelData.title ? DesktopEntries.heuristicLookup(modelData.title)?.name : "")
                || modelData.title || modelData.tooltipTitle || modelData.id

            implicitWidth: chip.implicitWidth + Theme.spacing.m * 2
            implicitHeight: Theme.icon.tray + Theme.spacing.s * 2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            Accessible.role: Accessible.Button
            Accessible.name: name
            Accessible.onPressAction: modelData.activate()

            onClicked: event => {
                // Some apps only have a menu (onlyMenu); open it on any click for those.
                if (event.button === Qt.LeftButton && !modelData.onlyMenu)
                    modelData.activate();
                else if (event.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (modelData.hasMenu)
                    menu.open();
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius.full
                color: Colors.m3surfaceContainerHighest
            }

            // State layer on hover.
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius.full
                color: Colors.m3onSurface
                opacity: item.containsMouse ? Theme.state.hover : 0
            }

            Row {
                id: chip
                anchors.centerIn: parent
                spacing: Theme.spacing.s

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: Theme.icon.tray
                    source: item.icon
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: item.name
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }
            }

            // Opens the item's menu (exported over D-Bus by the app) just below the icon.
            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.item: item
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
                anchor.margins.top: Theme.spacing.m
            }
        }
    }
}
