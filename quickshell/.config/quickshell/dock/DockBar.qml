import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// The dock on one monitor, macOS style (user's choice): a rounded bar floating a little above the
// bottom edge. It stays out of sight until the pointer touches the bottom edge (user's choice,
// since windows tile and would cover it).
PanelWindow {
    id: window

    required property var dock // Dock.qml: items, pinned, togglePin()

    // The bar, centered at the bottom.
    readonly property real bodyWidth: row.implicitWidth + Theme.spacing.m * 2
    readonly property real bodyHeight: Theme.dock.height

    // The pointer is at the bottom edge or on the dock, or its menu is open. Stays true for a
    // moment after the pointer leaves, so the dock doesn't flicker away.
    readonly property bool wanted: trigger.containsMouse || hitArea.containsMouse || menu.visible
                                   || previews.hovered
    property bool revealed: false
    onWantedChanged: {
        if (wanted) {
            hideDelay.stop();
            revealed = true;
        } else {
            hideDelay.restart();
        }
    }

    readonly property bool shown: revealed
    onShownChanged: {
        if (shown)
            DockState.shownOn = screen.name;
        else if (DockState.shownOn === screen.name)
            DockState.shownOn = "";
    }

    Timer {
        id: hideDelay
        interval: Theme.dock.hideDelay
        onTriggered: window.revealed = false
    }

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    // Room above the dock for the tooltips and the right-click menu.
    implicitHeight: Theme.dock.height + Theme.dock.margin + Theme.dock.menuSpace
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Input only on the dock (or, while hidden, the thin strip at the bottom edge) and the menu.
    // While shown it's hitArea: where the dock ends up, down to the screen edge. Not the sliding
    // bar itself: right after the reveal that's still below the screen, the pointer would be
    // outside the input area, and the dock would take that as the pointer leaving and hide again.
    mask: Region {
        item: window.shown ? hitArea : trigger

        Region {
            item: menu.visible ? menu : null
        }

        Region {
            item: previews.visible ? previews : null
        }
    }

    // Blur behind exactly the dock and its cards (ext-background-effect; replaces a layer rule
    // that blurred every pixel above 30 % opacity).
    BackgroundEffect.blurRegion: Region {
        item: shape
        radius: Theme.dock.radius

        Region {
            item: menu.visible ? menu : null
            radius: menu.radius
        }

        Region {
            item: previews.visible ? previews : null
            radius: previews.radius
        }

        // While the dock is hidden its bar is below the window, so the region would be empty,
        // and Hyprland 0.57 then blurs the whole window (a 1920x308 panel), though the protocol
        // says nothing should be blurred. One pixel in the window's transparent corner keeps it
        // from being empty.
        Region {
            width: 1
            height: 1
        }
    }

    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Closes the menu when you click anywhere else.
    HyprlandFocusGrab {
        windows: [window]
        active: menu.visible
        onCleared: menu.item = null
    }

    // The bottom edge: touch it to bring a hidden dock back.
    MouseArea {
        id: trigger
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: window.bodyWidth
        height: Theme.dock.trigger
        hoverEnabled: true
    }

    // Where the shown dock is, down to the screen edge (so the pointer can go from the edge to the
    // dock without leaving it). A MouseArea to know whether the pointer is on the dock; clicks go
    // to the icons inside it. It doesn't move; the bar and icons slide inside it.
    MouseArea {
        id: hitArea

        anchors.horizontalCenter: parent.horizontalCenter
        y: window.height - height
        width: window.bodyWidth
        height: window.bodyHeight + Theme.dock.margin
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        // The bar. Slides down out of sight while hidden.
        Surface {
            id: shape

            y: window.shown ? 0 : hitArea.height + Theme.spacing.s
            width: parent.width
            height: window.bodyHeight
            radius: Theme.dock.radius

            Behavior on y {
                MorphAnimation {}
            }
        }

        // The apps, on the bar.
        Item {
            id: content

            y: shape.y
            width: parent.width
            height: window.bodyHeight

            Row {
                id: row
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height

                Repeater {
                    // Recomputed every second (window positions); ScriptModel keeps the icons
                    // whose app didn't change instead of rebuilding them all.
                    model: ScriptModel { values: window.dock.items }

                    Row {
                        id: slot

                        required property var modelData
                        required property int index

                        height: row.height

                        // A thin line between the pinned apps and the other running ones.
                        Rectangle {
                            visible: slot.index > 0 && !slot.modelData.pinned && window.dock.items[slot.index - 1].pinned
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: Theme.dock.icon * 0.6
                            color: Colors.m3outlineVariant
                        }

                        DockItem {
                            item: slot.modelData
                            previewing: previews.item === slot.modelData && previews.visible
                            // Resting on an app with windows shows them above the dock.
                            onContainsMouseChanged: {
                                if (containsMouse && windows.length > 0 && menu.item === null)
                                    previews.request(slot.modelData, mapToItem(window.contentItem, width / 2, 0).x);
                                else
                                    previews.release();
                            }
                            onMenuRequested: {
                                previews.close();
                                menu.item = slot.modelData;
                                menu.anchorX = mapToItem(window.contentItem, width / 2, 0).x;
                            }
                        }
                    }
                }
            }
        }
    }

    // Right-click menu: new window, pin or unpin, close the app's windows.
    Surface {
        id: menu

        property var item: null
        property real anchorX
        readonly property DesktopEntry entry: item && !item.id.startsWith("app:") ? DesktopEntries.byId(item.id) : null

        function run(action: var): void {
            action();
            item = null;
        }

        visible: item !== null
        x: Math.max(Theme.spacing.s, Math.min(window.width - width - Theme.spacing.s, anchorX - width / 2))
        y: hitArea.y - height
        width: Theme.dock.menuWidth
        height: actions.implicitHeight + Theme.spacing.s * 2
        radius: Theme.radius.l

        Column {
            id: actions
            anchors.centerIn: parent
            width: parent.width - Theme.spacing.s * 2

            component MenuRow: MouseArea {
                id: entryRow
                property string icon
                property string text
                width: parent.width
                height: Theme.list.rowHeight - Theme.spacing.m
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.MenuItem
                Accessible.name: text
                Accessible.onPressAction: entryRow.clicked(null)

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.m
                    color: Colors.m3onSurface
                    opacity: entryRow.containsMouse ? Theme.state.hover : 0
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.m
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.m

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: entryRow.icon
                        font.pixelSize: Theme.icon.small
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: entryRow.text
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                    }
                }
            }

            MenuRow {
                visible: menu.entry !== null
                icon: "add"
                text: "New window"
                onClicked: menu.run(() => Apps.launch(menu.entry))
            }

            // The app's own shortcuts from its .desktop file ("New Private Window", Steam's
            // "Library"). Its "New Window" is the row above already.
            Repeater {
                model: (menu.entry?.actions ?? []).filter(a => a.name.toLowerCase() !== "new window")

                MenuRow {
                    required property DesktopAction modelData
                    icon: "open_in_new"
                    text: modelData.name
                    onClicked: menu.run(() => modelData.execute())
                }
            }

            MenuRow {
                visible: menu.entry !== null
                icon: menu.item?.pinned ? "keep_off" : "keep"
                text: menu.item?.pinned ? "Unpin from dock" : "Pin to dock"
                onClicked: menu.run(() => window.dock.togglePin(menu.item.id))
            }

            MenuRow {
                visible: (menu.item?.windows.length ?? 0) > 0
                icon: "close"
                text: (menu.item?.windows.length ?? 0) > 1 ? "Close all windows" : "Close window"
                onClicked: menu.run(() => menu.item.windows.forEach(w => Windows.close(w.window)))
            }
        }
    }

    // Window previews of the app the pointer rests on (Theme.dock.previewDelay), like Windows'
    // taskbar: click one to switch to it. The pointer can move up from the icon onto them; they
    // close a moment after it leaves both.
    Surface {
        id: previews

        property var item: null
        property var wanted: null // the app the pointer is on, until the delay passes
        property real anchorX
        readonly property bool hovered: previewHover.hovered
        readonly property list<HyprlandToplevel> windows: (item?.windows ?? []).map(w => w.window)

        function request(app: var, x: real): void {
            closeDelay.stop();
            wanted = app;
            anchorX = x;
            if (item !== null)
                item = app; // already showing: switch right away
            else
                openDelay.restart();
        }

        function release(): void {
            openDelay.stop();
            closeDelay.restart();
        }

        function close(): void {
            openDelay.stop();
            closeDelay.stop();
            item = null;
        }

        visible: item !== null && windows.length > 0
        x: Math.max(Theme.spacing.s, Math.min(window.width - width - Theme.spacing.s, anchorX - width / 2))
        y: hitArea.y - height - Theme.spacing.s
        width: thumbs.implicitWidth + Theme.spacing.s * 2
        height: thumbs.implicitHeight + Theme.spacing.s * 2
        radius: Theme.radius.l

        Timer {
            id: openDelay
            interval: Theme.dock.previewDelay
            onTriggered: previews.item = previews.wanted
        }

        Timer {
            id: closeDelay
            interval: Theme.dock.hideDelay
            onTriggered: {
                if (!previews.hovered)
                    previews.item = null;
            }
        }

        HoverHandler {
            id: previewHover
            onHoveredChanged: hovered ? closeDelay.stop() : closeDelay.restart()
        }

        Row {
            id: thumbs
            anchors.centerIn: parent
            spacing: Theme.spacing.s

            Repeater {
                model: previews.windows

                MouseArea {
                    id: thumb

                    required property HyprlandToplevel modelData
                    // The window's shape at the preview height, not wider than Alt+Tab allows.
                    readonly property real aspect: Math.min(Theme.switcher.maxAspect,
                        (modelData.lastIpcObject?.size?.[0] ?? 16) / (modelData.lastIpcObject?.size?.[1] ?? 10))

                    width: Theme.dock.preview * aspect
                    height: Theme.dock.preview + Theme.switcher.labelHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        previews.close();
                        Windows.show(modelData);
                    }

                    Accessible.role: Accessible.Button
                    Accessible.name: "Switch to " + modelData.title
                    Accessible.onPressAction: Windows.show(modelData)

                    WindowPreview {
                        anchors.fill: parent
                        toplevel: thumb.modelData
                        previewHeight: Theme.dock.preview
                        highlighted: thumb.containsMouse
                        capturing: previews.visible
                        closable: true
                    }
                }
            }
        }
    }
}
