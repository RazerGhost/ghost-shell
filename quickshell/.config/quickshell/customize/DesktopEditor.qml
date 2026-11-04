import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.desktop
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../services/ColorScheme.js" as ColorSchemeJs
import "../settings/HyprlandConfig.js" as HyprlandConfig
import "../theme/ThemeScale.js" as ThemeScale
import "../desktop/DesktopWidgets.js" as DesktopWidgetsJs
import "Presets.js" as Presets
import "Themes.js" as Themes
import "../services/FileUrl.js" as FileUrl

// The desktop editor, like Android's "Wallpaper & style": the real desktop, drawn as a card. Opening
// it goes to an empty workspace (windows would cover the desktop) and Done or Cancel go back;
// the island and dock stay, so new colors and sizes show on them at once. The sheet has the
// wallpaper, the colors, the desktop widgets (their handles show, drag them), the panels'
// style, and sizes and fonts. Cancel writes the earlier settings and wallpaper back. Opened
// from Settings -> Appearance and the launcher (Customize.qml).
Scope {
    id: root

    property var saved: ({})
    // The screen it opened on, kept while it's open (the focused one could change under it).
    property string screenName: ""
    property string savedWallpaper: ""

    function open(): void {
        if (editor.active)
            return;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        saved = Presets.snapshot(Settings.values, Presets.desktopKeys);
        savedWallpaper = Wallpaper.path;
        Editing.toEmptyWorkspace();
        Wallpaper.rescan();
        Editing.desktop = true;
        Editing.hideDock = true;
        editor.active = true;
    }

    function close(): void {
        if (!editor.active)
            return;
        editor.active = false;
        Editing.widget = "";
        Editing.desktop = false;
        Editing.hideDock = false;
        Editing.back();
    }

    // Closed first: its widget layouts would save the restored settings into a layout of yours.
    function cancel(): void {
        close();
        Presets.restore(Settings.values, saved);
        if (Wallpaper.target !== savedWallpaper) {
            if (savedWallpaper !== "")
                Wallpaper.set(savedWallpaper);
            else
                Wallpaper.clear();
        }
    }

    // Icon themes: the installed ones, their dark and light versions as one (matugen's
    // wallpaper.sh picks the version for the mode).
    property var iconThemes: ["Colloid"]
    // The theme the shell started with (hypr/shell.sh exports it with its dark or light
    // version's suffix): its own icons stay that until it restarts.
    readonly property string startIconTheme: (Quickshell.env("QS_ICON_THEME") ?? "").replace(/-(Dark|Light|dark|light)$/, "")

    Process {
        command: ["sh", "-c", `for d in /usr/share/icons/*/index.theme "$HOME"/.local/share/icons/*/index.theme; do
            [ -f "$d" ] || continue
            n=$(basename "$(dirname "$d")")
            case "$n" in *-Dark|*-Light|*-dark|hicolor|locolor|default|AdwaitaLegacy) continue ;; esac
            grep -q "^Directories=" "$d" && echo "$n"
        done`]
        running: editor.active
        stdout: StdioCollector {
            onStreamFinished: root.iconThemes = text.split("\n").filter(n => n !== "").sort((a, b) => a.localeCompare(b))
        }
    }

    LazyLoader {
        id: editor

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(s => s.name === root.screenName) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // The desktop as a card between the island and the sheet (like GNOME's workspaces):
            // the wallpaper and the widgets draw themselves into it (customize/Editing.qml), the
            // background color around it. It follows the sheet's height as tabs change.
            Connections {
                target: chrome
                function onCardChanged(): void {
                    Editing.card = chrome.card;
                }
            }
            Component.onCompleted: Editing.showCard(window, screen?.name ?? "", chrome.card)
            Component.onDestruction: Editing.hideCard(window)

            // Input only on the sheet: the desktop widgets underneath can be dragged.
            mask: Region {
                item: chrome.sheet
            }

            // Hyprland's blur behind the sheet and buttons, like the shell's panels: the glass,
            // see-through and blur style settings show on the sheet while they're changed.
            BackgroundEffect.blurRegion: Region {
                item: chrome.sheet
                radius: chrome.sheet.radius
            }

            EditorChrome {
                id: chrome
                extraHints: tab === "widgets" ? [{ keys: ["Shift", "←↑↓→"], label: "Move the widget" }] : []
                tabs: [
                    { value: "looks", label: "Looks" },
                    { value: "themes", label: "Themes" },
                    { value: "wallpaper", label: "Wallpaper" },
                    { value: "colors", label: "Colors" },
                    { value: "widgets", label: "Widgets" },
                    { value: "style", label: "Style" },
                    { value: "text", label: "Size and text" }
                ]
                cardTop: Theme.island.reserved + Theme.spacing.l * 2
                // The colors take about a second to be made again after these changes.
                status: Wallpaper.busy || ColorScheme.busy ? "Making the colors…" : ""
                onCancelled: root.cancel()
                onFinished: root.close()

                // Looks: the style presets over your wallpaper (a panel in each look's glass and
                // corners; how it draws the colors shows once picked), and the widget layouts (a
                // fitting set of widgets, each at its place).
                SheetTiles {
                    visible: chrome.tab === "looks"

                    LooksTile {
                        live: editor.active
                        picture: Wallpaper.stillPath
                        title: "Style"
                        subtitle: "Glass, blur, corners and color style, over your wallpaper"
                        presets: Presets.desktop
                        fadeColor: Qt.tint(Colors.surfaceTranslucent, Colors.tint)
                        art: Component {
                            Item {
                                id: look
                                readonly property var values: parent.option.values


                                // A panel as the shell would draw it in this look.
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.62
                                    height: parent.height * 0.5
                                    radius: Theme.radius.m * look.values.cornerScale
                                    color: Qt.rgba(Colors.m3surfaceContainer.r, Colors.m3surfaceContainer.g, Colors.m3surfaceContainer.b,
                                                   look.values.glass ? look.values.glassOpacity / 100 : Theme.surfaceOpacity)
                                    border.width: look.values.glass ? Theme.glass.edge : 0
                                    // The look's edge, not the one you have now.
                                    border.color: Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, Theme.glass.edgeAlpha)

                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.7
                                        spacing: Theme.spacing.xs

                                        Rectangle {
                                            width: parent.width * 0.35
                                            height: Theme.spacing.s
                                            radius: height / 2 * Math.min(look.values.cornerScale, 1)
                                            color: Colors.m3primary
                                        }

                                        Repeater {
                                            model: 2

                                            Rectangle {
                                                width: parent.width * (index === 0 ? 1 : 0.7)
                                                height: Theme.spacing.xs
                                                radius: height / 2 * Math.min(look.values.cornerScale, 1)
                                                color: Colors.m3onSurfaceVariant
                                                opacity: 0.6
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    LooksTile {
                        live: editor.active
                        picture: Wallpaper.stillPath
                        title: "Widget layouts"
                        savedKey: "widgetLooks"
                        savedPrefix: "My layout"
                        subtitle: "Which widgets, and where"
                        presets: Presets.desktopWidgets
                        fadeColor: Qt.tint(Colors.surfaceTranslucent, Colors.tint)
                        art: Component {
                            Item {
                                id: layout
                                readonly property var values: parent.option.values


                                // Each widget that's on, at its place and size on the screen, shrunk.
                                Repeater {
                                    model: DesktopWidgetsJs.kinds.filter(k => layout.values[k.key])

                                    Rectangle {
                                        required property var modelData
                                        readonly property real unit: layout.width / Math.max(Screen.width, 1)
                                        readonly property var box: Theme.desktop.box(modelData.name)
                                        // Where it shows on the screen at the shell's size, shrunk.
                                        readonly property var at: DesktopWidgetsJs.shown(
                                            DesktopWidgetsJs.place(layout.values.desktopWidgets, modelData.name), box.w, box.h,
                                            Screen.width, Screen.height, Theme.desktop.zoom)

                                        x: at.x * unit
                                        y: at.y * unit
                                        width: box.w * unit
                                        height: box.h * unit
                                        radius: Theme.desktop.radius * unit
                                        color: Colors.sketch
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: DesktopWidgetsJs.kinds.every(k => !layout.values[k.key])
                                    text: "No widgets"
                                    color: Colors.m3onSurface
                                    font.family: Theme.font.sans
                                    font.pixelSize: Theme.font.small
                                }
                            }
                        }
                    }
                }

                // Themes: your saved looks, like Android's (Themes.js): the wallpaper with the
                // accent and font on it; click one to switch to it. Saving and deleting beside.
                SheetTiles {
                    id: themesTab

                    readonly property var themes: Themes.valid(Settings.values.themes)
                    readonly property string current: Themes.current(themes, Settings.values, Wallpaper.path)

                    // Whether a theme's picture is still there (none counts as there): a deleted one
                    // can't be set, so its theme isn't applied halfway.
                    function hasPicture(theme: var): bool {
                        return theme.wallpaper === "" || theme.wallpaper === Wallpaper.path
                            || Wallpaper.pictures.some(p => p.filePath === theme.wallpaper || p.darkPath === theme.wallpaper);
                    }

                    // Its settings, then its wallpaper (which remakes the colors with them).
                    function use(name: string): void {
                        const theme = themes.find(t => t.name === name);
                        if (!theme || !hasPicture(theme))
                            return;
                        Presets.restore(Settings.values, Themes.applicable(theme.values, Settings.values));
                        if (theme.wallpaper !== Wallpaper.target) {
                            if (theme.wallpaper !== "")
                                Wallpaper.set(theme.wallpaper);
                            else
                                Wallpaper.clear();
                        }
                    }

                    visible: chrome.tab === "themes"

                    SheetTile {
                        title: "Themes"
                        subtitle: "Wallpaper, colors, style, fonts and widgets in one click"
                        weight: 3

                        Text {
                            anchors.centerIn: parent
                            visible: themesTab.themes.length === 0
                            text: "No themes yet. Make the desktop look the way you like, then save it."
                            color: Colors.m3onSurfaceVariant
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                        }

                        ChoiceCards {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            visible: themesTab.themes.length > 0
                            fadeColor: Qt.tint(Colors.surfaceTranslucent, Colors.tint)
                            scrolls: true
                            cardWidth: Theme.editor.pictureCard
                            options: themesTab.themes.map(t => ({ value: t.name, theme: t,
                                                                  label: themesTab.hasPicture(t) ? t.name : t.name + " · picture gone" }))
                            current: themesTab.current
                            onPicked: v => themesTab.use(v)
                            art: Component {
                                Item {
                                    id: look
                                    readonly property var theme: parent.option.theme
                                    opacity: themesTab.hasPicture(theme) ? 1 : Theme.state.disabled

                                    Rectangle {
                                        anchors.fill: parent
                                        color: look.theme.primary || Colors.m3surfaceContainerHighest
                                    }

                                    Image {
                                        anchors.fill: parent
                                        readonly property var picture: Wallpaper.pictures.find(p => p.filePath === look.theme.wallpaper)
                                        // A video by its thumbnail; without one (not scanned), just the color.
                                        readonly property string file: picture?.video ? picture.thumb ?? ""
                                                                     : Wallpaper.isVideoPath(look.theme.wallpaper) ? "" : look.theme.wallpaper
                                        source: FileUrl.of(file)
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: width * 2
                                        asynchronous: true
                                    }

                                    // The accent and the font, on a chip like the shell's panels.
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.margins: Theme.spacing.s
                                        width: sampleRow.width + Theme.spacing.s * 2
                                        height: sampleRow.height + Theme.spacing.xs * 2
                                        radius: height / 2
                                        color: Colors.m3surfaceContainerHighest

                                        Row {
                                            id: sampleRow
                                            anchors.centerIn: parent
                                            spacing: Theme.spacing.xs

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: Theme.font.normal
                                                height: width
                                                radius: width / 2
                                                color: look.theme.primary || Colors.m3primary
                                            }

                                            Text {
                                                text: "Aa"
                                                color: Colors.m3onSurface
                                                font.family: look.theme.values.fontSans || Theme.font.defaultSans
                                                font.pixelSize: Theme.font.normal
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: themesTab.current || "This look"
                        subtitle: themesTab.current ? "Saved as a theme; type to rename it" : "Not saved yet"

                        Column {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: Theme.spacing.m

                            // The current theme's name, to change: Enter keeps it (an empty or
                            // taken name is ignored).
                            TextField {
                                id: themeName
                                width: parent.width
                                visible: themesTab.current !== ""
                                placeholder: "Name"
                                // Set, not bound: typing would end a binding.
                                Component.onCompleted: text = themesTab.current
                                Connections {
                                    target: themesTab
                                    function onCurrentChanged(): void {
                                        themeName.text = themesTab.current;
                                    }
                                }
                                keepsEscape: true
                                // An empty or taken name isn't kept: the field shows the name again.
                                onAccepted: {
                                    Settings.values.themes = Themes.renamed(themesTab.themes, themesTab.current, text);
                                    text = themesTab.current;
                                }
                                onEscaped: text = themesTab.current
                                Accessible.name: "The theme's name"
                            }

                            TextButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: themesTab.current === ""
                                text: "Save as a theme"
                                filled: true
                                onClicked: Settings.values.themes = themesTab.themes.concat(
                                    [Themes.made(themesTab.themes, Settings.values, Wallpaper.path, Colors.primaryTarget.toString())])
                            }

                            TextButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Delete " + themesTab.current
                                visible: themesTab.current !== ""
                                onClicked: Settings.values.themes = Themes.removed(themesTab.themes, themesTab.current)
                            }

                            // Across machines (ghost looks): your themes and every editor's looks
                            // into the repo's looks.json, or from it.
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Theme.spacing.s

                                TextButton {
                                    text: "Export"
                                    onClicked: looksShare.start([Quickshell.env("HOME") + "/.local/bin/ghost", "looks", "export"])
                                }

                                TextButton {
                                    text: "Import"
                                    onClicked: looksShare.start([Quickshell.env("HOME") + "/.local/bin/ghost", "looks", "import"])
                                }
                            }

                            Process {
                                id: looksShare
                                stdout: StdioCollector {
                                    id: shareOut
                                }
                                stderr: StdioCollector {
                                    id: shareErr
                                }
                                function start(command: var): void {
                                    looksShare.command = command;
                                    looksShare.running = true;
                                }
                                // Export says where they went; import's own notice comes from the
                                // shell when it merges (Customize.qml).
                                onExited: code => {
                                    if (code !== 0)
                                        Notifications.send("Customize", "dialog-warning", "Couldn't share the looks",
                                                           shareErr.text.trim() || "ghost looks exited with " + code, false, []);
                                    else if (looksShare.command[2] === "export")
                                        Notifications.send("Customize", "preferences-desktop-theme", "Looks exported",
                                                           shareOut.text.trim(), false, []);
                                }
                            }
                        }
                    }
                }

                // Wallpaper: yours, videos as their still frame; more from the Wallpapers window.
                SheetTiles {
                    visible: chrome.tab === "wallpaper"

                    SheetTile {
                        title: "Wallpaper"
                        subtitle: "From your folder; the colors come from it"

                        ChoiceCards {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            // Fades into the tile, over the glass sheet.
                            fadeColor: Qt.tint(Colors.surfaceTranslucent, Colors.tint)
                            scrolls: true
                            cardWidth: Theme.editor.pictureCard
                            options: Wallpaper.pictures.map(p => ({ value: p.filePath, label: p.fileName, thumb: p.video ? p.thumb : p.filePath }))
                            current: Wallpaper.target
                            onPicked: v => Wallpaper.set(v)
                            art: Component {
                                Image {
                                    source: FileUrl.of(parent.option.thumb)
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: width * 2
                                    asynchronous: true
                                }
                            }
                        }
                    }

                    // More art: the launcher's Wallpapers page (wallpaper/WallpaperBrowser.qml). It
                    // shows under the editor, so the editor finishes first, keeping your changes,
                    // like Done.
                    SheetTile {
                        title: "More art"
                        subtitle: "Find pictures on wallhaven.cc"
                        natural: Theme.editor.slider

                        TextButton {
                            anchors.centerIn: parent
                            text: "Find wallpapers"
                            filled: true
                            onClicked: {
                                root.close();
                                LauncherState.show("wallpapers");
                            }
                        }
                    }
                }

                // Colors: light or dark, the accent as swatches, how the colors are drawn, contrast.
                SheetTiles {
                    visible: chrome.tab === "colors"

                    SheetTile {
                        title: "Light or dark"
                        subtitle: Settings.values.colorScheme === "auto" ? "Dark from sunset to sunrise" : ""

                        Segmented {
                            anchors.centerIn: parent
                            options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }, { value: "auto", label: "At sunset" }]
                            current: Settings.values.colorScheme
                            onPicked: v => Settings.values.colorScheme = v
                        }
                    }

                    SheetTile {
                        weight: 1.3
                        title: "Accent"
                        subtitle: Settings.values.accentColor ? "Instead of the wallpaper's" : "From the wallpaper"

                        // The wallpaper's own (its picture in the circle), then fixed colors.
                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacing.s

                            Repeater {
                                model: [
                                    { value: "", label: "The wallpaper's" }, { value: "#6750a4", label: "Purple" },
                                    { value: "#1e66f5", label: "Blue" }, { value: "#00897b", label: "Teal" },
                                    { value: "#43a047", label: "Green" }, { value: "#fb8c00", label: "Orange" },
                                    { value: "#e53935", label: "Red" }, { value: "#d81b60", label: "Pink" }
                                ]

                                ClippingRectangle {
                                    id: swatch
                                    required property var modelData
                                    readonly property bool chosen: Settings.values.accentColor === modelData.value

                                    width: Theme.icon.normal + Theme.spacing.s * 2
                                    height: width
                                    radius: width / 2
                                    color: modelData.value || Colors.m3primary
                                    border.width: chosen ? Theme.outline.strong : 0
                                    border.color: Colors.m3onSurface

                                    Accessible.role: Accessible.RadioButton
                                    Accessible.name: modelData.label
                                    Accessible.checked: chosen
                                    Accessible.onPressAction: Settings.values.accentColor = modelData.value
                                    activeFocusOnTab: true
                                    Keys.onReturnPressed: Settings.values.accentColor = modelData.value
                                    Keys.onEnterPressed: Settings.values.accentColor = modelData.value
                                    Keys.onSpacePressed: Settings.values.accentColor = modelData.value

                                    Image {
                                        anchors.fill: parent
                                        visible: swatch.modelData.value === ""
                                        source: FileUrl.of(Wallpaper.stillPath)
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize: Qt.size(width * 2, height * 2)
                                        asynchronous: true
                                    }

                                    StateLayer {
                                        radius: swatch.radius
                                        color: Colors.m3onSurface
                                        hovered: swatchMouse.containsMouse
                                    }

                                    FocusRing {
                                        radius: swatch.radius
                                    }

                                    MouseArea {
                                        id: swatchMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.values.accentColor = swatch.modelData.value
                                    }
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Color style"
                        subtitle: "How the colors are drawn from the wallpaper"
                        weight: 1.6

                        Grid {
                            id: styleGrid
                            anchors.centerIn: parent
                            width: parent.width
                            columns: 3
                            spacing: Theme.spacing.s

                            Repeater {
                                model: ColorSchemeJs.styles

                                OptionChip {
                                    required property string modelData
                                    width: (styleGrid.width - styleGrid.spacing * 2) / 3
                                    text: ({
                                        "scheme-tonal-spot": "Tonal", "scheme-vibrant": "Vibrant",
                                        "scheme-expressive": "Expressive", "scheme-content": "Content",
                                        "scheme-fidelity": "Faithful", "scheme-fruit-salad": "Fruit salad",
                                        "scheme-rainbow": "Rainbow", "scheme-neutral": "Neutral",
                                        "scheme-monochrome": "Mono"
                                    })[modelData] ?? modelData
                                    chosen: Settings.values.colorStyle === modelData
                                    onClicked: Settings.values.colorStyle = modelData
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Contrast"

                        Segmented {
                            anchors.centerIn: parent
                            options: [{ value: -0.5, label: "Lower" }, { value: 0, label: "Standard" },
                                      { value: 0.5, label: "Higher" }, { value: 1, label: "Highest" }]
                            current: Settings.values.colorContrast
                            onPicked: v => Settings.values.colorContrast = v
                        }
                    }
                }

                // Widgets: a gallery of the widgets themselves (click one to put it on the desktop
                // or take it off, like iOS's), and their places.
                SheetTiles {
                    visible: chrome.tab === "widgets"

                    SheetTile {
                        id: galleryTile
                        title: "Widgets"
                        subtitle: "Click one to put it on your desktop or take it off"
                        weight: 5

                        ListView {
                            id: gallery
                            anchors.fill: parent
                            orientation: ListView.Horizontal
                            spacing: Theme.spacing.l
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: [
                                { key: "desktopClock", title: "Clock", widget: clockWidget },
                                { key: "desktopWeather", title: "Weather", widget: weatherWidget },
                                { key: "desktopForecast", title: "Weather, hourly", widget: forecastWidget },
                                { key: "desktopCalendar", title: "Calendar", widget: calendarWidget },
                                { key: "desktopMonth", title: "Month", widget: monthWidget },
                                { key: "desktopTodo", title: "To-do", widget: todoWidget },
                                { key: "desktopTasks", title: "To-do list", widget: tasksWidget },
                                { key: "desktopNote", title: "Note", widget: noteWidget },
                                { key: "desktopClipboard", title: "Clipboard", widget: clipboardWidget },
                                { key: "desktopTimer", title: "Timer", widget: timerWidget },
                                { key: "desktopNotifications", title: "Notifications", widget: notificationsWidget },
                                { key: "desktopBattery", title: "Battery", widget: batteryWidget },
                                { key: "desktopMedia", title: "Media", widget: mediaWidget }
                            ].filter(w => w.key !== "desktopBattery" || Battery.present)

                            delegate: Item {
                                id: entry

                                required property var modelData
                                required property int index
                                readonly property bool on: Settings.values[modelData.key]
                                // The widget scaled to the gallery's height, less its name.
                                readonly property real zoom: preview.item ? (gallery.height - name.height - Theme.spacing.s) / Math.max(preview.item.height, 1) : 1

                                // Turned on, it goes where it's clear of the widgets showing
                                // (DesktopWidgets.freePlace): beside them rather than over them.
                                function toggle(): void {
                                    if (!on) {
                                        const name = DesktopWidgetsJs.kinds.find(k => k.key === modelData.key).name;
                                        const others = DesktopWidgetsJs.kinds
                                            .filter(k => k.name !== name && Settings.values[k.key] && (k.name !== "battery" || Battery.present))
                                            .map(k => k.name);
                                        const screen = Quickshell.screens[0];
                                        if (screen)
                                            Settings.values.desktopWidgets = DesktopWidgetsJs.freePlace(
                                                Settings.values.desktopWidgets, name, others, screen.width, screen.height);
                                    }
                                    Settings.values[modelData.key] = !on;
                                }

                                width: (preview.item?.width ?? 0) * zoom
                                height: gallery.height

                                Accessible.role: Accessible.CheckBox
                                Accessible.name: modelData.title + " on the desktop"
                                Accessible.checkable: true
                                Accessible.checked: on
                                Accessible.onPressAction: toggle()
                                activeFocusOnTab: true
                                Keys.onReturnPressed: toggle()
                                Keys.onEnterPressed: toggle()
                                Keys.onSpacePressed: toggle()
                                // Shift + arrows move this widget on the desktop (one grid step, or
                                // Theme.spacing.l * 2 without the grid); it's outlined there.
                                Keys.onPressed: event => {
                                    const direction = ({ [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down" })[event.key];
                                    if (!(event.modifiers & Qt.ShiftModifier) || !direction || !on)
                                        return;
                                    const kind = DesktopWidgetsJs.kinds.find(k => k.key === modelData.key);
                                    const screen = Quickshell.screens[0];
                                    const grid = Settings.values.desktopGrid ? Theme.px(DesktopWidgetsJs.gridSize(Settings.values.desktopGridSize)) : 0;
                                    const { dx, dy } = DesktopWidgetsJs.keyStep(direction, grid, Theme.spacing.l * 2);
                                    const box = Theme.desktop.box(kind.name);
                                    const place = DesktopWidgetsJs.nudged(DesktopWidgetsJs.place(Settings.values.desktopWidgets, kind.name), dx, dy,
                                                                          box.w, box.h,
                                                                          screen?.width ?? 1920, screen?.height ?? 1080, grid,
                                                                          Theme.desktop.zoom);
                                    Settings.values.desktopWidgets = DesktopWidgetsJs.withPlace(Settings.values.desktopWidgets, kind.name, place);
                                    event.accepted = true;
                                }
                                // Tab to one further along: the row scrolls to show it. The widget it
                                // stands for is outlined on the desktop meanwhile.
                                onActiveFocusChanged: {
                                    const name = DesktopWidgetsJs.kinds.find(k => k.key === modelData.key)?.name ?? "";
                                    if (activeFocus) {
                                        gallery.positionViewAtIndex(index, ListView.Contain);
                                        Editing.widget = name;
                                    } else if (Editing.widget === name) {
                                        Editing.widget = "";
                                    }
                                }

                                Loader {
                                    id: preview
                                    enabled: false
                                    sourceComponent: entry.modelData.widget
                                    scale: entry.zoom
                                    transformOrigin: Item.TopLeft
                                    opacity: entry.on ? 1 : Theme.state.disabled
                                    Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }
                                }

                                // Its name, with a check while it's on.
                                Row {
                                    id: name
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Theme.spacing.xs

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        icon: entry.on ? "check_circle" : "add_circle"
                                        color: entry.on ? Colors.m3primary : Colors.m3onSurfaceVariant
                                        font.pixelSize: Theme.icon.small
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: entry.modelData.title
                                        color: entry.on ? Colors.m3onSurface : Colors.m3onSurfaceVariant
                                        font.family: Theme.font.sans
                                        font.pixelSize: Theme.font.small
                                        font.weight: Font.Medium
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: entry.toggle()
                                }

                                FocusRing {
                                    radius: Theme.desktop.radius * entry.zoom
                                }
                            }
                        }

                        Component { id: clockWidget; ClockWidget {} }
                        Component { id: weatherWidget; WeatherWidget {} }
                        Component { id: calendarWidget; CalendarWidget {} }
                        Component { id: forecastWidget; ForecastWidget {} }
                        Component { id: monthWidget; MonthWidget {} }
                        Component { id: tasksWidget; TasksWidget { large: true } }
                        Component { id: noteWidget; NoteWidget {} }
                        Component { id: clipboardWidget; ClipboardWidget {} }
                        Component { id: todoWidget; TasksWidget {} }
                        Component { id: batteryWidget; BatteryWidget {} }
                        Component { id: timerWidget; TimerWidget {} }
                        Component { id: notificationsWidget; NotificationsWidget {} }
                        Component { id: mediaWidget; MediaWidget {} }

                        // More to the right: it fades out there (the tile's shade over the sheet).
                        Rectangle {
                            anchors.right: gallery.right
                            width: Theme.spacing.l * 3
                            height: gallery.height
                            visible: !gallery.atXEnd
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: Qt.tint(Colors.surfaceTranslucent, Colors.tint) }
                            }
                        }
                    }

                    // Places: dragging, and the grid widgets line up with (lines out from the
                    // screen's middle, so placements can mirror each other).
                    SheetTile {
                        title: "Places"
                        subtitle: Settings.values.desktopGrid ? "Drag a widget: it lines up with the grid (px apart)"
                                                               : "Drag a widget by its handle"
                        weight: 1.8

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: Theme.spacing.m

                            TileRow {
                                label: "Grid"

                                Switch {
                                    label: "Line widgets up with a grid"
                                    checked: Settings.values.desktopGrid
                                    onToggled: Settings.values.desktopGrid = !checked
                                }
                            }

                            TileRow {
                                label: "Size"
                                opacity: Settings.values.desktopGrid ? 1 : Theme.state.disabled
                                enabled: Settings.values.desktopGrid

                                Segmented {
                                    options: DesktopWidgetsJs.gridSizes.map(v => ({ value: v, label: String(v) }))
                                    current: DesktopWidgetsJs.gridSize(Settings.values.desktopGridSize)
                                    onPicked: v => Settings.values.desktopGridSize = v
                                }
                            }

                            TextButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Put them back"
                                enabled: Object.keys(Settings.values.desktopWidgets ?? {}).length > 0
                                onClicked: Settings.values.desktopWidgets = ({})
                            }
                        }
                    }
                }

                // Style: the glass (a panel over your wallpaper shows it), the blur styles (this
                // sheet shows them) and the corners (a sample shows them).
                SheetTiles {
                    visible: chrome.tab === "style"

                    SheetTile {
                        title: "Glass"
                        subtitle: Settings.values.glass ? Settings.values.glassOpacity + " % solid" : "Off: panels nearly solid"
                        weight: 1.2
                        action: Switch {
                            label: "Glass panels"
                            checked: Settings.values.glass
                            onToggled: Settings.values.glass = !checked
                        }

                        ClippingRectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: glassSlider.top
                            anchors.bottomMargin: Theme.spacing.s
                            radius: Theme.radius.m
                            color: Colors.m3surfaceContainerHighest

                            Image {
                                anchors.fill: parent
                                source: FileUrl.of(Wallpaper.stillPath)
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: width * 2
                                asynchronous: true
                            }

                            // A panel like the island's menus, at the glass setting.
                            Surface {
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: parent.height * 0.6
                                radius: Theme.radius.m

                                Text {
                                    anchors.centerIn: parent
                                    text: "Panel"
                                    color: Colors.m3onSurface
                                    font.family: Theme.font.sans
                                    font.pixelSize: Theme.font.normal
                                }
                            }
                        }

                        LevelSlider {
                            id: glassSlider
                            anchors.bottom: parent.bottom
                            width: parent.width
                            enabled: Settings.values.glass
                            opacity: enabled ? 1 : Theme.state.disabled
                            icon: "opacity"
                            label: "How solid the glass is"
                            value: (Settings.values.glassOpacity - 20) / 65
                            onMoved: v => Settings.values.glassOpacity = 20 + Math.round(v * 13) * 5
                        }
                    }

                    SheetTile {
                        title: "Blur"
                        subtitle: "Behind glass and menus: this sheet shows it"
                        weight: 1.2

                        Grid {
                            anchors.centerIn: parent
                            width: parent.width
                            columns: 3
                            spacing: Theme.spacing.s

                            Repeater {
                                model: HyprlandConfig.blurStyles

                                OptionChip {
                                    required property string modelData
                                    width: (parent.width - parent.spacing * 2) / 3
                                    text: ({ kawase: "Classic", frost: "Frost", acrylic: "Acrylic", prism: "Prism",
                                             aurora: "Aurora", haze: "Haze" })[modelData] ?? modelData
                                    chosen: HyprlandConfig.blurStyle(Settings.values.blurStyle) === modelData
                                    onClicked: Settings.values.blurStyle = modelData
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Corners"
                        subtitle: "The shell's panels and buttons"

                        // A panel's corner at the setting.
                        Rectangle {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: cornerChoice.top
                            anchors.bottomMargin: Theme.spacing.s
                            width: parent.width * 0.55
                            radius: Theme.radius.l * 1.5
                            color: Colors.m3primaryContainer
                            Behavior on radius { NumberAnimation { duration: Theme.anim.normal } }
                        }

                        Segmented {
                            id: cornerChoice
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            options: ThemeScale.corners.map(v => ({ value: v, label: ({ 0: "Square", 0.5: "Less", 1: "Round", 1.5: "More" })[v] }))
                            current: Theme.cornerScale
                            onPicked: v => Settings.values.cornerScale = v
                        }
                    }
                }

                // Size and text: the shell's size and its text (a sample shows them), the font
                // (each in itself) and the icon theme.
                SheetTiles {
                    visible: chrome.tab === "text"

                    SheetTile {
                        title: "Size"
                        subtitle: "The shell, and its text on top"
                        weight: 1.3

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: Theme.spacing.s

                            Text {
                                width: parent.width
                                text: "The island, menus and dock"
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.large
                                elide: Text.ElideRight
                            }

                            Repeater {
                                model: [
                                    { label: "Shell", values: ThemeScale.sizes, current: Theme.scale, key: "uiScale" },
                                    { label: "Text", values: ThemeScale.textSizes, current: Theme.textScale, key: "textScale" }
                                ]

                                Row {
                                    id: sizeRow
                                    required property var modelData
                                    spacing: Theme.spacing.m

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Theme.editor.label
                                        text: sizeRow.modelData.label
                                        color: Colors.m3onSurfaceVariant
                                        font.family: Theme.font.sans
                                        font.pixelSize: Theme.font.small
                                    }

                                    Segmented {
                                        // No wider than the tile (at large sizes it ran into the next one).
                                        maxWidth: sizeRow.parent.width - Theme.editor.label - sizeRow.spacing
                                        options: sizeRow.modelData.values.map(v => ({ value: v, label: Math.round(v * 100) + " %" }))
                                        current: sizeRow.modelData.current
                                        onPicked: v => Settings.values[sizeRow.modelData.key] = v
                                    }
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Font"
                        subtitle: "The shell's menus, island and Settings"
                        weight: 1.6

                        Grid {
                            id: fontGrid
                            readonly property var fonts: ["Inter", "Adwaita Sans", "Cantarell", "Noto Sans", "Open Sans", "Roboto",
                                                          "IBM Plex Sans", "Fira Sans", "Ubuntu", "DejaVu Sans"]
                                                         .filter(f => Qt.fontFamilies().includes(f))
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            columns: Math.max(3, Math.ceil(fonts.length / 2))
                            spacing: Theme.spacing.s

                            Repeater {
                                model: fontGrid.fonts

                                OptionChip {
                                    required property string modelData
                                    width: (fontGrid.width - fontGrid.spacing * (fontGrid.columns - 1)) / fontGrid.columns
                                    sample: true
                                    sampleFont: modelData
                                    text: modelData
                                    chosen: Theme.font.sans === modelData
                                    onClicked: Settings.values.fontSans = modelData === "Inter" ? "" : modelData
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Monospaced"
                        subtitle: "Error messages and code"
                        weight: 1.4

                        Grid {
                            id: monoGrid
                            readonly property var fonts: ["MesloLGS Nerd Font", "JetBrainsMono Nerd Font", "JetBrains Mono", "Fira Code",
                                                          "Adwaita Mono", "Noto Sans Mono", "DejaVu Sans Mono", "Source Code Pro", "Hack"]
                                                         .filter(f => Qt.fontFamilies().includes(f))
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            columns: Math.max(2, Math.ceil(fonts.length / 2))
                            spacing: Theme.spacing.s

                            Repeater {
                                model: monoGrid.fonts

                                OptionChip {
                                    required property string modelData
                                    width: (monoGrid.width - monoGrid.spacing * (monoGrid.columns - 1)) / monoGrid.columns
                                    sample: true
                                    sampleFont: modelData
                                    text: modelData.replace(" Nerd Font", "")
                                    chosen: Theme.font.mono === modelData
                                    onClicked: Settings.values.fontMono = modelData === "MesloLGS Nerd Font" ? "" : modelData
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Icons"
                        subtitle: "Apps' icons; the dock's after a restart"

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacing.m

                            Stepper {
                                anchors.horizontalCenter: parent.horizontalCenter
                                label: "Icon theme"
                                values: root.iconThemes
                                valueWidth: Theme.settings.stepperWide
                                value: Settings.values.iconTheme
                                format: v => v.replace(/^Colloid-?/, "Colloid ").trim()
                                onPicked: v => Settings.values.iconTheme = v
                            }

                            // The shell reads the icon theme when it starts (QS_ICON_THEME, hypr/shell.sh).
                            TextButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: Settings.values.iconTheme !== root.startIconTheme
                                text: "Restart the shell"
                                filled: true
                                onClicked: {
                                    root.close();
                                    Quickshell.execDetached(["sh", "-c", "pkill -x qs; sleep 1; exec \"$HOME\"/.config/hypr/shell.sh"]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
