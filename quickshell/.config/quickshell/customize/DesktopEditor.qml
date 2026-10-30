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
import "Presets.js" as Presets

// The desktop editor, like Android's "Wallpaper & style": the real desktop, drawn as a card. Opening
// it goes to an empty workspace (windows would cover the desktop) and Done or Cancel go back;
// the island and dock stay, so new colors and sizes show on them at once. The sheet has the
// wallpaper, the colors, the desktop widgets (their handles show, drag them), the panels'
// style, and sizes and fonts. Cancel writes the earlier settings and wallpaper back. Opened
// from Settings -> Appearance and the launcher (Customize.qml).
Scope {
    id: root

    property var saved: ({})
    property string savedWallpaper: ""

    function open(): void {
        if (editor.active)
            return;
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
        Editing.desktop = false;
        Editing.hideDock = false;
        Editing.back();
    }

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        if (Wallpaper.path !== savedWallpaper && savedWallpaper !== "")
            Wallpaper.set(savedWallpaper);
        close();
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

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
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
            Component.onCompleted: {
                Editing.card = chrome.card;
                Editing.cardScreen = screen?.name ?? "";
            }
            Component.onDestruction: Editing.cardScreen = ""

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
                tabs: [
                    { value: "wallpaper", label: "Wallpaper" },
                    { value: "colors", label: "Colors" },
                    { value: "widgets", label: "Widgets" },
                    { value: "style", label: "Style" },
                    { value: "text", label: "Size and text" }
                ]
                glass: true
                cardTop: Theme.island.height + Theme.spacing.l * 2
                // The colors take about a second to be made again after these changes.
                status: Wallpaper.busy || ColorScheme.busy ? "Making the colors…" : ""
                onCancelled: root.cancel()
                onFinished: root.close()

                // Wallpaper: yours and the built-in ones, videos as their still frame.
                SheetTiles {
                    visible: chrome.tab === "wallpaper"

                    SheetTile {
                        title: "Wallpaper"
                        subtitle: "Yours and the built-in ones; the colors come from it"

                        ChoiceCards {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            // Fades into the tile, over the glass sheet.
                            fadeColor: Qt.tint(Colors.surfaceTranslucent, Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, 0.05))
                            scrolls: true
                            cardWidth: Theme.editor.pictureCard
                            options: Wallpaper.pictures.map(p => ({ value: p.filePath, label: p.fileName, thumb: p.video ? p.thumb : p.filePath }))
                            current: Wallpaper.path
                            onPicked: v => Wallpaper.set(v)
                            art: Component {
                                Image {
                                    source: "file://" + parent.option.thumb
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: width * 2
                                    asynchronous: true
                                }
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
                                    Keys.onSpacePressed: Settings.values.accentColor = modelData.value

                                    Image {
                                        anchors.fill: parent
                                        visible: swatch.modelData.value === ""
                                        source: Wallpaper.stillPath ? "file://" + Wallpaper.stillPath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize: Qt.size(width * 2, height * 2)
                                        asynchronous: true
                                    }

                                    FocusRing {
                                        radius: swatch.radius
                                    }

                                    MouseArea {
                                        anchors.fill: parent
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

                // Widgets: a tile per widget with a look at it and its switch, and their places.
                SheetTiles {
                    visible: chrome.tab === "widgets"

                    Repeater {
                        model: [
                            { key: "desktopClock", title: "Clock", subtitle: "The time and date" },
                            { key: "desktopWeather", title: "Weather", subtitle: "Today's, for your town" },
                            { key: "desktopMedia", title: "Media", subtitle: "While something plays" }
                        ]

                        SheetTile {
                            id: widgetTile

                            required property var modelData
                            readonly property bool on: Settings.values[modelData.key]

                            title: modelData.title
                            subtitle: modelData.subtitle
                            action: Switch {
                                label: widgetTile.modelData.title + " on the desktop"
                                checked: widgetTile.on
                                onToggled: Settings.values[widgetTile.modelData.key] = !checked
                            }

                            // The widget itself, scaled to fit, dimmed while it's off; clicking toggles.
                            Item {
                                anchors.fill: parent
                                opacity: widgetTile.on ? 1 : Theme.state.disabled
                                Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

                                Loader {
                                    anchors.centerIn: parent
                                    enabled: false
                                    sourceComponent: ({ desktopClock: clockWidget, desktopWeather: weatherWidget,
                                                        desktopMedia: mediaWidget })[widgetTile.modelData.key]
                                    scale: item ? Math.min(parent.width / item.width, parent.height / item.height, 1) : 1
                                }

                                Component { id: clockWidget; ClockWidget {} }
                                Component { id: weatherWidget; WeatherWidget {} }
                                Component { id: mediaWidget; MediaWidget {} }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.values[widgetTile.modelData.key] = !widgetTile.on
                                }
                            }
                        }
                    }

                    SheetTile {
                        title: "Places"
                        subtitle: "Drag a widget by its handle"

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacing.m

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: "drag_pan"
                                color: Colors.m3onSurfaceVariant
                                font.pixelSize: Theme.font.title * 1.6
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
                                source: Wallpaper.stillPath ? "file://" + Wallpaper.stillPath : ""
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
                        weight: 2

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
