import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.theme

// System tray (StatusNotifierItem): left click activates, middle click is the secondary
// action, right click opens the app's menu.
Row {
    spacing: Theme.spacing.s

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: item

            required property SystemTrayItem modelData

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Theme.icon.tray
            implicitHeight: Theme.icon.tray
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            Accessible.role: Accessible.Button
            Accessible.name: modelData.tooltipTitle || modelData.title || modelData.id
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

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
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
