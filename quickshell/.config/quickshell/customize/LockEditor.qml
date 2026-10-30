import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.lock
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../lock/LockClock.js" as LockClockJs
import "../lock/LockWidgets.js" as LockWidgets
import "../widgets/OrderedList.js" as OrderedList
import "Presets.js" as Presets

// The lock screen editor, like long-pressing the iOS lock screen: the real lock screen, live,
// as a card on the background color, with Cancel and Done at the top and a sheet at the bottom with the looks (presets), the
// clock and the picture. Every change shows at once; Cancel puts the values from before back.
// The clock is outlined: clicking it opens the clock's tab. Opened from Settings -> Lock screen
// and the launcher (Customize.qml). The login screen follows (greeter/sync.sh).
Scope {
    id: root

    // The lock screen's settings as they were when the editor opened, for Cancel.
    property var saved: ({})
    // The screen it opened on, kept while it's open (the focused one could change under it).
    property string screenName: ""

    function open(): void {
        if (editor.active)
            return;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        saved = Presets.snapshot(Settings.values, Presets.lockKeys);
        Wallpaper.rescan();
        editor.active = true;
    }

    function done(): void {
        editor.active = false;
    }

    function close(): void {
        if (editor.active)
            root.done();
    }

    // The clock, date and widgets moved `by` (px of the lock screen) from where they are now:
    // saved as where they ended up (clamped by LockContent), as fractions of the screen.
    function moveClock(by: point): void {
        const lock = editor.item?.lockContent;
        if (!lock)
            return;
        lock.dragShift = by;
        // clockShift holds the saved offset and the move together, clamped.
        const shift = lock.clockShift;
        Settings.values.lockClockOffset = { x: shift.x / lock.width, y: shift.y / lock.height };
        lock.dragShift = Qt.point(0, 0);
    }

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        editor.active = false;
    }

    LazyLoader {
        id: editor

        PanelWindow {
            id: window

            readonly property Item lockContent: lock

            screen: Quickshell.screens.find(s => s.name === root.screenName) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Colors.m3surface
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // The lock screen as a card (EditorChrome.card), laid out at the screen's size and
            // scaled into it, on the background color.
            ClippingRectangle {
                id: card
                x: chrome.card.x
                y: chrome.card.y
                width: chrome.card.width
                height: chrome.card.height
                radius: Theme.radius.l * 1.5
                color: "black"

                Item {
                    width: window.width
                    height: window.height
                    scale: chrome.cardScale
                    transformOrigin: Item.TopLeft

                    // The lock screen itself, with input off.
                    LockContent {
                        id: lock
                        anchors.fill: parent
                        wallpaper: Wallpaper.lockPath
                        enabled: false
                        takesKeyboard: false

                        LockStatus {
                            id: status
                            width: parent.width
                        }
                    }

                    // The clock and the widgets under it, outlined like an iOS lock screen being
                    // edited; click one for its tab.
                    EditOutline {
                        readonly property Item clock: lock.clockItem
                        readonly property Item column: clock?.parent ?? null

                        sheet: chrome
                        tab: "clock"
                        name: "The clock's options"
                        shown: (clock?.visible ?? false) || chrome.tab === "clock"
                        area: Qt.rect((column?.x ?? 0) + lock.clockShift.x + (clock?.x ?? 0),
                                      (column?.y ?? 0) + lock.clockShift.y + (clock?.y ?? 0),
                                      clock?.width ?? 0, clock?.height ?? 0)
                        onMoving: by => lock.dragShift = by
                        onMoved: by => root.moveClock(by)
                    }

                    EditOutline {
                        // LockStatus in the clock's column (through LockContent's slot under the date).
                        readonly property Item slot: status.parent
                        readonly property Item column: slot?.parent ?? null

                        sheet: chrome
                        tab: "widgets"
                        name: "The widgets' options"
                        shown: status.height > 0 || chrome.tab === "widgets"
                        area: Qt.rect((column?.x ?? 0) + lock.clockShift.x + (slot?.x ?? 0) + status.contentX,
                                      (column?.y ?? 0) + lock.clockShift.y + (slot?.y ?? 0) + (slot?.topPadding ?? 0),
                                      status.contentWidth, Math.max(status.height, Theme.lock.widget))
                        onMoving: by => lock.dragShift = by
                        onMoved: by => root.moveClock(by)
                    }
                }
            }

            EditorChrome {
                id: chrome
                tabs: [
                    { value: "looks", label: "Looks" },
                    { value: "clock", label: "Clock" },
                    { value: "picture", label: "Picture" },
                    { value: "widgets", label: "Widgets" }
                ]
                onCancelled: root.cancel()
                onFinished: root.done()

                // Looks: your picture with each preset's clock on it, and first your own look
                // while it matches none of them ("" is yours).
                SheetTiles {
                    visible: chrome.tab === "looks"

                    SheetTile {
                        title: "Looks"
                        subtitle: "Your picture with each look's clock"

                        ChoiceCards {
                            anchors.centerIn: parent
                            options: (Presets.current(Settings.values, Presets.lock) === "" ? [{ value: "", label: "Yours" }] : [])
                                .concat(Presets.lock.map(p => ({ value: p.name, label: p.name })))
                            current: Presets.current(Settings.values, Presets.lock)
                            onPicked: v => {
                                if (v !== "")
                                    Presets.apply(Settings.values, Presets.lock, v);
                            }
                            art: Component {
                                Item {
                                    id: look
                                    readonly property var values: parent.option.value === "" ? Settings.values
                                        : Presets.lock.find(p => p.name === parent.option.value).values

                                    Image {
                                        anchors.fill: parent
                                        source: Wallpaper.lockPath ? "file://" + Wallpaper.lockPath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: width * 2
                                        asynchronous: true
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "black"
                                        opacity: look.values.lockDim / 100 + 0.1
                                    }

                                    MiniClock {
                                        box: look
                                        style: look.values.lockClockStyle
                                        family: look.values.lockClockFont || Theme.font.sans
                                        fill: 0.5
                                        // Placed by its shrunk size, like the look's place on the screen.
                                        transformOrigin: Item.TopLeft
                                        x: look.values.lockLayout === "left" ? look.width * 0.08 : (look.width - width * scale) / 2
                                        y: look.values.lockLayout === "top" ? look.height * 0.12
                                           : look.values.lockLayout === "center" ? (look.height - height * scale) / 2 : look.height * 0.88 - height * scale
                                    }
                                }
                            }
                        }
                    }
                }

                // Clock: style and font as tall cards, and the clock's place, size and what it
                // shows, each a tile.
                SheetTiles {
                    visible: chrome.tab === "clock"
                    tileHeight: Math.round(Theme.editor.clockCard * 1.1) + Theme.editor.tileChrome

                    SheetTile {
                        title: "Style"
                        natural: styleCards.width

                        ChoiceCards {
                            id: styleCards
                            anchors.centerIn: parent
                            cardWidth: Theme.editor.clockCard
                            cardHeight: Math.round(Theme.editor.clockCard * 1.1)
                            options: LockClockJs.styles.map(v => ({ value: v, label: ({ big: "Big", stacked: "Stacked", thin: "Thin", analog: "Analog" })[v] }))
                            current: LockClockJs.pick(Settings.values.lockClockStyle, LockClockJs.styles)
                            onPicked: v => Settings.values.lockClockStyle = v
                            art: Component {
                                Rectangle {
                                    color: Colors.m3surfaceContainerHighest

                                    MiniClock {
                                        anchors.centerIn: parent
                                        box: parent
                                        style: parent.parent.option.value
                                    }
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Font"
                        subtitle: "The date keeps the shell's"
                        // Takes what Style and "Place and size" leave; its cards scroll when they
                        // don't fit (a larger shell size).
                        weight: 1.6

                        ChoiceCards {
                            id: fontCards
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            scrolls: true
                            fadeColor: Qt.tint(chrome.solid, Colors.tint)
                            cardWidth: Theme.editor.clockCard
                            cardHeight: Math.round(Theme.editor.clockCard * 1.1)
                            options: ["", "Inter Display", "Noto Serif", "C059", "Nimbus Sans Narrow", "MesloLGS Nerd Font"]
                                .filter(f => f === "" || Qt.fontFamilies().includes(f))
                                .map(f => ({ value: f, label: f === "" ? "Same as text" : f === "MesloLGS Nerd Font" ? "Monospaced" : f }))
                            current: Settings.values.lockClockFont
                            onPicked: v => Settings.values.lockClockFont = v
                            art: Component {
                                Rectangle {
                                    color: Colors.m3surfaceContainerHighest

                                    Text {
                                        anchors.centerIn: parent
                                        text: "10:09"
                                        color: Colors.m3onSurface
                                        font.family: parent.parent.option.value || Theme.font.sans
                                        font.pixelSize: Math.min(parent.height * 0.36, parent.width * 0.24)
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Place and size"

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: Theme.spacing.m

                            TileRow {
                                label: "Place"

                                Segmented {
                                    options: LockClockJs.layouts.map(v => ({ value: v, label: ({ top: "Top", center: "Middle", left: "Bottom left" })[v] }))
                                    current: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts)
                                    // A place starts without a move of its own.
                                    onPicked: v => {
                                        Settings.values.lockLayout = v;
                                        Settings.values.lockClockOffset = null;
                                    }
                                }
                        }

                        TileRow {
                            label: "Size"

                            Segmented {
                                options: LockClockJs.sizes.map(v => ({ value: v, label: v + " %" }))
                                current: LockClockJs.pick(Settings.values.lockClockSize, LockClockJs.sizes)
                                onPicked: v => Settings.values.lockClockSize = v
                            }
                        }

                        TileRow {
                            label: "Show"

                            Row {
                                spacing: Theme.spacing.m

                                Repeater {
                                    model: [{ key: "lockClock", label: "Time" }, { key: "lockDate", label: "Date" }]

                                    Row {
                                        id: shown
                                        required property var modelData
                                        spacing: Theme.spacing.s

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: shown.modelData.label
                                            color: Colors.m3onSurface
                                            font.family: Theme.font.sans
                                            font.pixelSize: Theme.font.normal
                                        }

                                        Switch {
                                            anchors.verticalCenter: parent.verticalCenter
                                            label: "Show the " + shown.modelData.label.toLowerCase()
                                            checked: Settings.values[shown.modelData.key]
                                            onToggled: Settings.values[shown.modelData.key] = !checked
                                        }
                                    }
                                }
                            }
                        }
                        }
                    }
                }

                // Picture: the desktop's or one of yours, and blur and darkening as sliders.
                SheetTiles {
                    visible: chrome.tab === "picture"
                    tileHeight: Theme.editor.tile + Theme.spacing.l

                    SheetTile {
                        title: "Picture"
                        subtitle: "The lock and login screens'"

                        ChoiceCards {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            // Fades into the tile, over the sheet.
                            fadeColor: Qt.tint(chrome.solid, Colors.tint)
                            // Larger than other cards: about as tall as the sliders beside them.
                            cardWidth: Theme.editor.pictureCard
                            scrolls: true
                            // Pictures only: the lock and login screens can't play a video.
                            options: [{ value: "", label: "Desktop's" }].concat(
                                Wallpaper.pictures.filter(p => !p.video).map(p => ({ value: p.filePath, label: p.fileName })))
                            current: Settings.values.lockWallpaper
                            onPicked: v => Settings.values.lockWallpaper = v
                            art: Component {
                                Image {
                                    readonly property string file: parent.option.value || Wallpaper.stillPath
                                    source: file ? "file://" + file : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: width * 2
                                    asynchronous: true
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Blur and darken"
                        natural: Theme.editor.slider

                        // Each slider with its value above it.
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacing.xs

                            Repeater {
                                model: [
                                    { name: "Blur", key: "lockBlur", most: 100, step: 10, icon: "blur_on" },
                                    { name: "Darken", key: "lockDim", most: 60, step: 5, icon: "contrast" }
                                ]

                                Column {
                                    id: amount
                                    required property var modelData
                                    readonly property int value: Settings.values[modelData.key]
                                    spacing: Theme.spacing.xs

                                    Text {
                                        text: amount.modelData.name + "  ·  " + (amount.value === 0 ? "Off" : amount.value + " %")
                                        color: Colors.m3onSurfaceVariant
                                        font.family: Theme.font.sans
                                        font.pixelSize: Theme.font.small
                                    }

                                    LevelSlider {
                                        width: Theme.editor.slider
                                        icon: amount.modelData.icon
                                        label: amount.modelData.name
                                        value: amount.value / amount.modelData.most
                                        onMoved: v => Settings.values[amount.modelData.key] = Math.round(v * amount.modelData.most / amount.modelData.step) * amount.modelData.step
                                    }
                                }
                            }
                        }
                    }
                }

                // Widgets: the round ones under the clock, picked like iOS's (in the order
                // clicked, up to four; the ones on come first, in the row's order, and drag onto
                // each other to change it), and the media controls.
                SheetTiles {
                    visible: chrome.tab === "widgets"

                    SheetTile {
                        id: widgetsTile

                        readonly property var list: LockWidgets.shown(Settings.values.lockWidgets, Settings.values)
                        readonly property var names: ({ weather: "Weather", battery: "Battery", notifications: "Notifications",
                                                        todo: "To-do", timer: "Timer", event: "Next event" })

                        title: "Under the clock"
                        subtitle: "Up to " + LockWidgets.most + " · drag to change their order · an event's title shows to anyone"
                        weight: 3

                        Row {
                            id: picks
                            anchors.centerIn: parent
                            spacing: Theme.spacing.l

                            Repeater {
                                model: widgetsTile.list.concat(LockWidgets.known.filter(id => !widgetsTile.list.includes(id)))
                                    .filter(id => id !== "battery" || Battery.present)

                                Column {
                                    id: pick

                                    required property string modelData
                                    readonly property int place: widgetsTile.list.indexOf(modelData)
                                    readonly property bool on: place >= 0
                                    readonly property bool full: widgetsTile.list.length >= LockWidgets.most

                                    function toggle(): void {
                                        Settings.values.lockWidgets = LockWidgets.toggled(widgetsTile.list, modelData);
                                    }

                                    function moveTo(to: int): void {
                                        Settings.values.lockWidgets = OrderedList.moved(widgetsTile.list, place, to);
                                    }

                                    spacing: Theme.spacing.s
                                    opacity: on ? 1 : full ? Theme.state.disabled / 2 : Theme.state.disabled
                                    Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

                                    Accessible.role: Accessible.CheckBox
                                    Accessible.name: widgetsTile.names[modelData] + " under the clock"
                                    Accessible.checkable: true
                                    Accessible.checked: on
                                    Accessible.onPressAction: toggle()
                                    activeFocusOnTab: true
                                    Keys.onReturnPressed: toggle()
                                    Keys.onEnterPressed: toggle()
                                    Keys.onSpacePressed: toggle()
                                    // Shift + Left / Right moves one that's on along the row.
                                    Keys.onPressed: event => {
                                        if (on && event.modifiers & Qt.ShiftModifier
                                                && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                                            const id = modelData;
                                            moveTo(place + (event.key === Qt.Key_Left ? -1 : 1));
                                            // The row is made again in its new order: the keyboard
                                            // stays on the one that moved.
                                            Qt.callLater(() => Array.from(picks.children).find(c => c.modelData === id)?.forceActiveFocus());
                                            event.accepted = true;
                                        }
                                    }

                                    Item {
                                        width: sample.width
                                        height: sample.height
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        // Over the others while dragged.
                                        z: dragArea.drag.active ? 1 : 0

                                        LockWidget {
                                            id: sample
                                            kind: pick.modelData
                                        }

                                        // Its place in the row while it's on.
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: -Theme.spacing.xs
                                            visible: pick.on
                                            width: Theme.icon.small + Theme.spacing.xs
                                            height: width
                                            radius: width / 2
                                            color: Colors.m3primary

                                            Text {
                                                anchors.centerIn: parent
                                                text: pick.place + 1
                                                color: Colors.m3onPrimary
                                                font.family: Theme.font.sans
                                                font.pixelSize: Theme.font.small
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        FocusRing {
                                            control: pick
                                            radius: height / 2
                                        }

                                        // Click to add or take off; drag one that's on onto another to put it
                                        // there.
                                        MouseArea {
                                            id: dragArea

                                            property bool dragged: false

                                            anchors.fill: parent
                                            cursorShape: drag.active ? Qt.ClosedHandCursor
                                                       : pick.on || !pick.full ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            drag.target: pick.on ? sample : null
                                            drag.onActiveChanged: if (drag.active) dragged = true
                                            onPressed: dragged = false
                                            onClicked: if (!dragged) pick.toggle()
                                            onReleased: {
                                                if (!dragged)
                                                    return;
                                                const at = sample.mapToItem(picks, sample.width / 2, sample.height / 2);
                                                const target = picks.childAt(at.x, at.y);
                                                sample.x = 0;
                                                sample.y = 0;
                                                if (target && target !== pick && target.on)
                                                    pick.moveTo(target.place);
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: widgetsTile.names[pick.modelData]
                                        color: Colors.m3onSurface
                                        font.family: Theme.font.sans
                                        font.pixelSize: Theme.font.small
                                    }
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Media controls"
                        subtitle: "Play, pause and skip without unlocking"
                        action: Switch {
                            label: "Media controls on the lock screen"
                            checked: Settings.values.lockMedia
                            onToggled: Settings.values.lockMedia = !checked
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "play_circle"
                            color: Settings.values.lockMedia ? Colors.m3primary : Colors.m3onSurfaceVariant
                            font.pixelSize: Theme.font.title * 2
                        }
                    }
                }
            }
        }
    }
}
