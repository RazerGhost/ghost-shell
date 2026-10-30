import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../services/ColorScheme.js" as ColorSchemeJs
import "../settings/HyprlandConfig.js" as HyprlandConfig
import "../theme/ThemeScale.js" as ThemeScale
import "Presets.js" as Presets

// The desktop editor, like Android's "Wallpaper & style": edited on the real desktop. Opening
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
        editor.active = true;
    }

    function close(): void {
        if (!editor.active)
            return;
        editor.active = false;
        Editing.desktop = false;
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
                // The colors take about a second to be made again after these changes.
                status: Wallpaper.busy || ColorScheme.busy ? "Making the colors…" : ""
                onCancelled: root.cancel()
                onFinished: root.close()

                // Wallpaper: yours and the built-in ones, videos as their still frame.
                ChoiceCards {
                    visible: chrome.tab === "wallpaper"
                    scrolls: true
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

                // Colors: light or dark, the accent as swatches, how they're drawn, contrast.
                Row {
                    visible: chrome.tab === "colors"
                    width: parent.width

                    Column {
                        width: parent.width / 2

                            SettingRow {
                                title: "Light or dark"
                                subtitle: Settings.values.colorScheme === "auto" ? "Dark from sunset to sunrise" : ""

                                Segmented {
                                    options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }, { value: "auto", label: "At sunset" }]
                                    current: Settings.values.colorScheme
                                    onPicked: v => Settings.values.colorScheme = v
                                }
                            }

                            SettingRow {
                                title: "Accent"
                                subtitle: Settings.values.accentColor ? "Instead of the wallpaper's" : "From the wallpaper"

                                // The wallpaper's own (its picture in the circle), then fixed colors.
                                Row {
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
                    }

                    Column {
                        width: parent.width / 2

                            SettingRow {
                                title: "Color style"
                                subtitle: "How the colors are drawn from the wallpaper"

                                Stepper {
                                    label: "Color style"
                                    values: ColorSchemeJs.styles
                                    valueWidth: Theme.settings.stepperWide
                                    value: Settings.values.colorStyle
                                    format: v => ({
                                        "scheme-tonal-spot": "Tonal (default)", "scheme-vibrant": "Vibrant",
                                        "scheme-expressive": "Expressive", "scheme-content": "Content",
                                        "scheme-fidelity": "Faithful", "scheme-fruit-salad": "Fruit salad",
                                        "scheme-rainbow": "Rainbow", "scheme-neutral": "Neutral",
                                        "scheme-monochrome": "Monochrome"
                                    })[v] ?? v
                                    onPicked: v => Settings.values.colorStyle = v
                                }
                            }

                            SettingRow {
                                title: "Contrast"

                                Segmented {
                                    options: [{ value: -0.5, label: "Lower" }, { value: 0, label: "Standard" },
                                              { value: 0.5, label: "Higher" }, { value: 1, label: "Highest" }]
                                    current: Settings.values.colorContrast
                                    onPicked: v => Settings.values.colorContrast = v
                                }
                            }
                    }
                }

                // Widgets: on or off; while this editor is open their handles show.
                Row {
                    visible: chrome.tab === "widgets"
                    width: parent.width

                    Column {
                        width: parent.width / 2

                            Repeater {
                                model: [
                                    { key: "desktopClock", title: "Clock", subtitle: "The time and date" },
                                    { key: "desktopWeather", title: "Weather", subtitle: "From the town in Weather and clock" },
                                    { key: "desktopMedia", title: "Media", subtitle: "While something plays" }
                                ]

                                SettingRow {
                                    id: widgetRow
                                    required property var modelData
                                    title: modelData.title
                                    subtitle: modelData.subtitle

                                    Switch {
                                        label: widgetRow.modelData.title + " on the desktop"
                                        checked: Settings.values[widgetRow.modelData.key]
                                        onToggled: Settings.values[widgetRow.modelData.key] = !checked
                                    }
                                }
                            }
                    }

                    Column {
                        width: parent.width / 2

                            SettingRow {
                                title: "Places"
                                subtitle: "Drag a widget by the handle in its corner to move it"

                                TextButton {
                                    text: "Back to the start"
                                    enabled: Object.keys(Settings.values.desktopWidgets ?? {}).length > 0
                                    onClicked: Settings.values.desktopWidgets = ({})
                                }
                            }
                    }
                }

                // Style: the shell's panels (glass and its blur) and corners.
                Row {
                    visible: chrome.tab === "style"
                    width: parent.width

                    Column {
                        width: parent.width / 2

                            SettingRow {
                                title: "Glass"
                                subtitle: "See-through panels with a thin light edge"

                                Switch {
                                    label: "Glass panels"
                                    checked: Settings.values.glass
                                    onToggled: Settings.values.glass = !checked
                                }
                            }

                            SettingRow {
                                visible: Settings.values.glass
                                title: "See-through"

                                Stepper {
                                    label: "Glass opacity"
                                    values: Array.from({ length: 14 }, (_, i) => 20 + i * 5)
                                    value: Settings.values.glassOpacity
                                    format: v => v + " %"
                                    onPicked: v => Settings.values.glassOpacity = v
                                }
                            }
                    }

                    Column {
                        width: parent.width / 2

                            SettingRow {
                                title: "Blur"
                                subtitle: "Behind the glass, menus and see-through windows"

                                Stepper {
                                    label: "Blur style"
                                    values: HyprlandConfig.blurStyles
                                    valueWidth: Theme.settings.stepperWide
                                    value: HyprlandConfig.blurStyle(Settings.values.blurStyle)
                                    format: v => ({ kawase: "Classic", frost: "Frost", acrylic: "Acrylic", prism: "Prism",
                                                    aurora: "Aurora", haze: "Haze" })[v] ?? v
                                    onPicked: v => Settings.values.blurStyle = v
                                }
                            }

                            SettingRow {
                                title: "Corners"
                                subtitle: "The shell's own"

                                Segmented {
                                    options: ThemeScale.corners.map(v => ({ value: v, label: ({ 0: "Square", 0.5: "Less", 1: "Round", 1.5: "More" })[v] }))
                                    current: Theme.cornerScale
                                    onPicked: v => Settings.values.cornerScale = v
                                }
                            }
                    }
                }

                // Size and text: the shell's size, its text, the fonts and the icons.
                Row {
                    visible: chrome.tab === "text"
                    width: parent.width

                    Column {
                        width: parent.width / 2

                            SettingRow {
                                title: "Shell size"

                                Segmented {
                                    options: ThemeScale.sizes.map(v => ({ value: v, label: Math.round(v * 100) + " %" }))
                                    current: Theme.scale
                                    onPicked: v => Settings.values.uiScale = v
                                }
                            }

                            SettingRow {
                                title: "Text size"

                                Segmented {
                                    options: ThemeScale.textSizes.map(v => ({ value: v, label: Math.round(v * 100) + " %" }))
                                    current: Theme.textScale
                                    onPicked: v => Settings.values.textScale = v
                                }
                            }
                    }

                    Column {
                        width: parent.width / 2

                            ChoiceCards {
                                title: "Font"
                                scrolls: true
                                options: ["Inter", "Adwaita Sans", "Cantarell", "Noto Sans", "Open Sans", "Roboto",
                                          "IBM Plex Sans", "Fira Sans", "Ubuntu", "DejaVu Sans"]
                                    .filter(f => Qt.fontFamilies().includes(f)).map(f => ({ value: f, label: f }))
                                current: Theme.font.sans
                                onPicked: v => Settings.values.fontSans = v === "Inter" ? "" : v
                                art: Component {
                                    Rectangle {
                                        color: Colors.m3surfaceContainerHighest

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Aa"
                                            color: Colors.m3onSurface
                                            font.family: parent.parent.option.value
                                            font.pixelSize: parent.height * 0.45
                                        }
                                    }
                                }
                            }

                            SettingRow {
                                title: "Icons"
                                subtitle: "Apps' icons; the shell's own (dock, launcher) after it restarts"

                                Stepper {
                                    label: "Icon theme"
                                    values: root.iconThemes
                                    valueWidth: Theme.settings.stepperWide
                                    value: Settings.values.iconTheme
                                    format: v => v.replace(/^Colloid-?/, "Colloid ").trim()
                                    onPicked: v => Settings.values.iconTheme = v
                                }
                            }

                            // The shell reads the icon theme when it starts (QS_ICON_THEME, hypr/shell.sh).
                            SettingRow {
                                visible: Settings.values.iconTheme !== root.startIconTheme
                                title: "Restart the shell for its own icons"
                                subtitle: "Keeps these changes; clears the notification list"

                                TextButton {
                                    text: "Restart"
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
