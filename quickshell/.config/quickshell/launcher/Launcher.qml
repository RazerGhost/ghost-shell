import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import qs.settings
import qs.wallpaper
import "Fuzzy.js" as Fuzzy
import "../settings/Keybinds.js" as Keybinds
import "../settings/SettingsPages.js" as SettingsPages

// App launcher: type to fuzzy-search installed apps and open windows, arrow keys to pick, Enter
// to launch or switch, Escape or a click outside to close. "/ name" searches files in the home
// folder (fd) and "> command" runs a command in the terminal (Fuzzy.mode, tested). Toggled with
// `qs ipc call launcher toggle` (tap Super or Super+Space).
// Settings and Wallpapers grow out of it (user's choice, 2026-10-31, instead of windows of
// their own): found by the search, or opened straight on them (Super+I, LauncherState), the card
// turns into the page at one of three sizes (compact, large, the whole screen; the buttons in its
// header or Ctrl+Up / Ctrl+Down). With nothing typed, the customize tiles sit above the apps
// (Super+U opens it with them selected; it was a menu of its own).
Scope {
    id: root

    // The shell's own entries, found like your commands: the on-screen editors (customize/) and
    // the Wallpapers window.
    readonly property var shellCommands: [
        { name: "Edit quick settings", command: "qs ipc call island editQuickSettings",
          icon: "preferences-system", subtitle: "Your tiles and buttons, in your order" },
        { name: "Customize the desktop", command: "qs ipc call customize desktop",
          icon: "preferences-desktop-wallpaper", subtitle: "Wallpaper, colors, widgets and style, on the desktop and lock screen" },
        { name: "Customize the dock and island", command: "qs ipc call customize dock",
          icon: "preferences-desktop-theme", subtitle: "The dock, workspace dots, clock and status icons, in place" },
        { name: "Customize the windows", command: "qs ipc call customize windows",
          icon: "preferences-system-windows", subtitle: "Borders, corners, gaps and animations, on your windows" },
        { name: "Wallpapers", page: "wallpapers",
          icon: "preferences-desktop-wallpaper", subtitle: "Find anime art on wallhaven.cc and download it" },
        { name: "Settings", page: "settings",
          icon: "preferences-system", subtitle: "Every setting, by page (Super + I)" }
    ]

    readonly property bool open: LauncherState.open
    readonly property string page: LauncherState.page

    // The customize tiles (Super+U), with nothing typed.
    readonly property var customizeTiles: [
        { id: "desktop", icon: "wallpaper", title: "Desktop", run: ["qs", "ipc", "call", "customize", "desktop"] },
        { id: "dock", icon: "dock_to_bottom", title: "Dock and island", run: ["qs", "ipc", "call", "customize", "dock"] },
        { id: "windows", icon: "select_window", title: "Windows", run: ["qs", "ipc", "call", "customize", "windows"] },
        { id: "quick", icon: "tune", title: "Quick settings", run: ["qs", "ipc", "call", "customize", "quick"] }
    ]

    function customize(tile: var): void {
        LauncherState.open = false;
        Quickshell.execDetached(tile.run);
    }

    // Back from a page: Settings' compact page to its list first, then to the search.
    function back(): void {
        if (page === "settings" && settingsLoader.item?.back())
            return;
        LauncherState.page = "";
        Qt.callLater(() => search.focusInput());
    }

    // A result: an app or one of its shortcuts ({ entry, action }; action null for the app), a
    // window ({ window }), a file ({ file }), a command to run ({ command }), a web search
    // ({ web }: DuckDuckGo in the default browser), a color ({ color }: copied) or a keybind
    // ({ keybind }: just shown).
    function launch(result: var): void {
        // A page of its own (Settings, Wallpapers): the card turns into it.
        if (result.setting) {
            LauncherState.showSettings(result.setting.id);
            return;
        }
        if (result.custom?.page) {
            LauncherState.show(result.custom.page);
            return;
        }
        if (result.web !== undefined)
            Apps.openPath("https://duckduckgo.com/?q=" + encodeURIComponent(result.web));
        else if (result.color)
            Quickshell.execDetached(["wl-copy", result.color]);
        else if (result.keybind)
            ; // nothing to run: the launcher just closes
        else if (result.window)
            Windows.show(result.window);
        else if (result.file)
            Apps.openPath(result.file.path);
        else if (result.custom)
            // Your own command (Settings -> Default apps), in its own scope like an app.
            Apps.run(["sh", "-c", result.custom.command], "command", "");
        else if (result.command)
            // The terminal stays open in your shell after the command, to read what it printed.
            Apps.runInTerminal(["sh", "-c", 'eval "$1"; exec "${SHELL:-sh}"', "sh", result.command]);
        else if (result.action)
            Apps.launchAction(result.action, result.entry);
        else
            Apps.launch(result.entry);
        LauncherState.open = false;
    }

    function appResults(text: string): var {
        const color = Fuzzy.color(text);
        const found = Fuzzy.results(DesktopEntries.applications.values, text,
                                    open && text.trim() !== "" ? windowList() : [],
                                    { favorites: Settings.values.launcherFavorites, hidden: Settings.values.launcherHidden,
                                      commands: Settings.values.launcherCommands.concat(root.shellCommands) });
        // Settings' pages that have it, after the apps (from two letters: one finds them all).
        const settings = text.trim().length >= 2 ? SettingsPages.matching(text).slice(0, 3).map(p => ({ setting: p })) : [];
        return (color ? [{ color: color }] : []).concat(found, settings, text.trim() !== "" ? [{ web: text.trim() }] : []);
    }

    // The keybinds for "? ...": read from Hyprland once per opening, when "?" is typed.
    property var keybindGroups: []
    onOpenChanged: keybindGroups = []

    Process {
        id: readBinds
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.keybindGroups = Keybinds.groups(JSON.parse(text));
                } catch (e) {
                    console.warn("Launcher: unexpected hyprctl binds output: " + e.message);
                }
            }
        }
    }

    // Open windows to search, with their app's name.
    function windowList(): var {
        return Hyprland.toplevels.values.map(t => ({
            window: t,
            title: t.title,
            app: DesktopEntries.heuristicLookup(t.wayland?.appId ?? "")?.name ?? t.wayland?.appId ?? ""
        }));
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            LauncherState.toggle();
        }

        // Super+.: the search in its emoji mode.
        function emoji(): void {
            LauncherState.showEmoji();
        }
    }

    // The default apps, for the keybinds: qs ipc call apps open terminal|browser|fileManager,
    // qs ipc call apps terminal yazi. Here because the Apps singleton only exists once used.
    IpcHandler {
        target: "apps"

        function open(kind: string): void {
            Apps.open(kind);
        }

        // `command` is split on spaces: no quoting.
        function terminal(command: string): void {
            Apps.runInTerminal(command.split(" "));
        }
    }

    // The launcher steps aside for what it opened: a window taking the focus (an app, a folder from
    // Settings), an on-screen editor (Customize.qml closes it).
    Connections {
        target: Hyprland

        function onActiveToplevelChanged(): void {
            if (root.open)
                LauncherState.open = false;
        }
    }

    PanelWindow {
        id: window

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: root.open

        // The whole screen, see-through; only the card takes input (`mask`), so a click beside it
        // reaches what's under it and closes the launcher (the focus grab). Fixed at the screen's
        // size so the card can grow and shrink smoothly inside it.
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: panel }

        WlrLayershell.namespace: "qs-launcher"

        // Blur behind the card (ext-background-effect; see NOTES.md).
        BackgroundEffect.blurRegion: Region { item: panel; radius: panel.radius }

        WlrLayershell.layer: WlrLayer.Overlay
        // Take the keyboard while open, so typing goes to the search field.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Closes the launcher when you click any other window or surface.
        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: LauncherState.open = false
        }

        // Super+. while it's already open: the search switches to emoji.
        Connections {
            target: LauncherState
            function onStartTextChanged(): void {
                if (window.visible && LauncherState.startText !== "") {
                    search.text = LauncherState.startText;
                    LauncherState.startText = "";
                    search.focusInput();
                }
            }
        }

        // The search starts fresh every time it opens; a page keeps its place.
        onVisibleChanged: {
            if (!visible)
                return;
            search.text = LauncherState.startText;
            LauncherState.startText = "";
            if (root.page === "")
                Qt.callLater(root.customizeFocus);
            else if (root.page === "settings")
                Qt.callLater(() => settingsLoader.item?.focusSearch());
        }

        Connections {
            target: LauncherState

            function onPageChanged(): void {
                if (!window.visible)
                    return;
                if (LauncherState.page === "settings")
                    Qt.callLater(() => settingsLoader.item?.focusSearch());
                else if (LauncherState.page === "")
                    Qt.callLater(() => search.focusInput());
            }

            function onCustomizeChanged(): void {
                if (window.visible)
                    Qt.callLater(root.customizeFocus);
            }
        }

        // The card: the search bar's size, or a page's at LauncherState.size, centered (full:
        // the screen below the island).
        readonly property int gap: Theme.spacing.l
        // The screen's size, not the window's: a freshly shown window starts smaller until
        // Hyprland gives it the screen, and the card would slide in from the top (user's find).
        readonly property real screenWidth: screen?.width ?? width
        readonly property real screenHeight: screen?.height ?? height
        readonly property size pageSize: LauncherState.size === "compact"
            ? Qt.size(Math.max(Theme.launcher.width, Theme.wallpaper.browserThumb * 2), Math.min(screenHeight - gap * 2, Theme.launcher.pageHeight))
            : LauncherState.size === "large"
            ? Qt.size(Math.min(screenWidth - gap * 2, Theme.launcher.pageWidth), Math.min(screenHeight - gap * 2, Theme.launcher.pageHeight))
            : Qt.size(screenWidth - gap * 2, screenHeight - Theme.island.reserved - gap * 2)

        Surface {
            id: panel

            readonly property bool paged: root.page !== ""
            width: paged ? window.pageSize.width : Theme.launcher.width
            height: paged ? window.pageSize.height : column.implicitHeight + Theme.spacing.m * 2
            x: (window.screenWidth - width) / 2
            y: paged && LauncherState.size === "full" ? Theme.island.reserved + window.gap : (window.screenHeight - height) / 2
            radius: Theme.radius.m * 2
            clip: true

            Behavior on width { enabled: window.visible; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            Behavior on height { enabled: window.visible; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            Behavior on y { enabled: window.visible; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }

            // Escape: back from a page (Settings' compact page to its list first), else close.
            // Ctrl+Up / Ctrl+Down: a page's size. Keys the controls don't use come here.
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (root.page !== "")
                        root.back();
                    else
                        LauncherState.open = false;
                    event.accepted = true;
                } else if (root.page !== "" && (event.modifiers & Qt.ControlModifier)
                           && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
                    LauncherState.resize(event.key === Qt.Key_Up ? 1 : -1);
                    event.accepted = true;
                }
            }
            Column {
                id: column

                x: Theme.spacing.m
                y: Theme.spacing.m
                width: Theme.launcher.width - Theme.spacing.m * 2
                spacing: Theme.spacing.s
                visible: !panel.paged

                SearchField {
                    id: search

                    readonly property var query: Fuzzy.mode(text)

                    width: parent.width
                    placeholder: "Search apps and windows,  / files,  > run,  ? keys,  : emoji"
                    fontSize: Theme.font.large

                    // New results: select the best match again (the answer, while there is one).
                    onTextChanged: {
                        list.currentIndex = 0;
                        // From the text itself: `query` may not have caught up with it yet here,
                        // and a search for the text before the last key was thrown away as stale.
                        const now = Fuzzy.mode(text);
                        if (now.mode === "keys" && root.keybindGroups.length === 0 && !readBinds.running)
                            readBinds.running = true;
                        calc.ask(now.mode === "apps" ? text : "");
                        if (now.mode === "files")
                            fileSearch.ask(now.text);
                    }
                    onKeyPressed: event => {
                        // Emoji mode: the arrow keys move through the grid, Enter picks.
                        if (query.mode === "emoji" && event.key !== Qt.Key_Escape) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                emojiGrid.pick();
                            else if (!emojiGrid.move(event.key))
                                return; // typing goes to the field
                            event.accepted = true;
                            return;
                        }
                        switch (event.key) {
                        case Qt.Key_Escape:
                            LauncherState.open = false;
                            break;
                        case Qt.Key_Up:
                            // From the top of the list to the customize tiles.
                            if (list.currentIndex <= 0 && !calc.selected && tiles.visible) {
                                tiles.itemAt(0)?.forceActiveFocus(Qt.TabFocusReason);
                                break;
                            }
                            if (list.currentIndex === 0 && calc.answer !== "")
                                calc.selected = true;
                            else
                                list.decrementCurrentIndex();
                            break;
                        case Qt.Key_Down:
                            if (calc.selected)
                                calc.selected = false;
                            else
                                list.incrementCurrentIndex();
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (calc.selected)
                                calc.copy();
                            else if (list.currentItem)
                                root.launch(list.currentItem.modelData);
                            break;
                        default:
                            return; // typing goes to the field
                        }
                        event.accepted = true;
                    }
                }

                // What to customize (Super+U; the menu it replaced): the on-screen editors and quick
                // settings' edit mode, with nothing typed. Left / Right between them, Down back to
                // the search; typing goes to the search.
                Row {
                    id: tileRow
                    visible: search.text === ""
                    width: parent.width
                    spacing: Theme.spacing.s

                    Accessible.role: Accessible.Grouping
                    Accessible.name: "Customize"

                    Repeater {
                        id: tiles
                        model: root.customizeTiles

                        Rectangle {
                            id: tile

                            required property var modelData
                            required property int index
                            readonly property bool lit: activeFocus || tileMouse.containsMouse

                            width: (tileRow.width - tileRow.spacing * (tiles.count - 1)) / Math.max(tiles.count, 1)
                            height: tileColumn.implicitHeight + Theme.spacing.m * 2
                            radius: Theme.radius.l
                            color: lit ? Colors.m3primaryContainer : Colors.tint
                            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

                            Accessible.role: Accessible.Button
                            Accessible.name: "Customize: " + modelData.title
                            Accessible.onPressAction: root.customize(modelData)
                            activeFocusOnTab: true
                            Keys.onReturnPressed: root.customize(modelData)
                            Keys.onEnterPressed: root.customize(modelData)
                            Keys.onSpacePressed: root.customize(modelData)
                            Keys.onLeftPressed: tiles.itemAt(Math.max(0, index - 1))?.forceActiveFocus(Qt.TabFocusReason)
                            Keys.onRightPressed: tiles.itemAt(Math.min(tiles.count - 1, index + 1))?.forceActiveFocus(Qt.TabFocusReason)
                            Keys.onDownPressed: search.focusInput()
                            Keys.onPressed: event => {
                                // Typing: into the search, which hides the tiles. Backspace (its
                                // text is a control character) only goes back to the search.
                                if (event.key === Qt.Key_Backspace) {
                                    search.focusInput();
                                    event.accepted = true;
                                } else if (/^[^\x00-\x20\x7f]/.test(event.text) && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                                    search.text += event.text;
                                    search.focusInput();
                                    event.accepted = true;
                                }
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.customize(tile.modelData)
                            }

                            FocusRing {
                                radius: tile.radius
                            }

                            Column {
                                id: tileColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.spacing.m
                                spacing: Theme.spacing.xs

                                MaterialIcon {
                                    icon: tile.modelData.icon
                                    color: tile.lit ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                                    font.pixelSize: Theme.icon.normal * 1.2
                                }

                                Text {
                                    width: parent.width
                                    text: tile.modelData.title
                                    color: tile.lit ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                                    font.family: Theme.font.sans
                                    font.pixelSize: Theme.font.small
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                CalcRow {
                    id: calc
                    width: parent.width
                    current: search.text
                    onCopied: LauncherState.open = false
                }

                FileSearch {
                    id: fileSearch
                    current: search.query.mode === "files" ? search.query.text : ""
                }

                EmojiGrid {
                    id: emojiGrid
                    width: parent.width
                    visible: search.query.mode === "emoji"
                    query: visible ? search.query.text : ""
                    onPicked: emoji => {
                        LauncherState.open = false;
                        Emoji.type(emoji);
                    }
                }

                ListView {
                    id: list

                    visible: search.query.mode !== "emoji"
                    width: parent.width
                    implicitHeight: Math.min(count, Theme.launcher.rows) * Theme.launcher.rowHeight
                    clip: true
                    // Re-filtered on every keystroke; DesktopEntries.applications updates
                    // by itself when apps are installed or removed. Includes the apps' own
                    // shortcuts ("New Private Window").
                    // ScriptModel: results that stay while typing keep their row.
                    model: ScriptModel {
                        values: search.query.mode === "files" ? fileSearch.found.map(f => ({ file: f }))
                              : search.query.mode === "command" ? (search.query.text === "" ? [] : [{ command: search.query.text }])
                              : search.query.mode === "keys" ? Fuzzy.keybinds(root.keybindGroups, search.query.text).map(k => ({ keybind: k }))
                              // A color first, the apps and windows, then the web; windows only
                              // while open with a query (their titles change all the time).
                              : root.appResults(search.text)
                    }
                    highlightMoveDuration: Theme.anim.fast
                    boundsBehavior: Flickable.StopAtBounds

                    Accessible.role: Accessible.List
                    Accessible.name: "Results"

                    highlight: Rectangle {
                        radius: Theme.radius.m
                        color: Colors.m3surfaceContainerHighest
                        visible: !calc.selected // the calculator's answer is selected instead
                    }

                    delegate: LauncherRow {
                        onActivated: root.launch(modelData)
                    }
                }

                Text {
                    visible: list.count === 0 && search.query.mode !== "emoji"
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spacing.s
                    bottomPadding: Theme.spacing.s
                    text: search.query.mode === "files" ? (search.query.text === "" ? "Type a file or folder name" : fileSearch.busy ? "Searching…" : "No files found")
                        : search.query.mode === "command" ? "Type a command to run in the terminal"
                        : search.query.mode === "keys" ? "No keybind found"
                        : "No apps found"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            // A page: Back, its name, the size buttons, and the page.
            Item {
                id: pageArea

                anchors.fill: parent
                anchors.margins: Theme.spacing.m
                visible: panel.paged

                Item {
                    id: pageHeader

                    width: parent.width
                    height: Theme.island.height

                    IconButton {
                        id: backButton
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "arrow_back"
                        label: "Back"
                        onClicked: root.back()
                    }

                    Text {
                        anchors.left: backButton.right
                        anchors.leftMargin: Theme.spacing.s
                        anchors.right: pageButtons.left
                        anchors.rightMargin: Theme.spacing.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.page === "settings"
                              ? "Settings" + (settingsLoader.item?.showsPage ? "  ·  " + (SettingsPages.find(LauncherState.settingsPage)?.title ?? "") : "")
                              : "Wallpapers"
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.title
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Accessible.role: Accessible.Heading
                        Accessible.name: text
                    }

                    Row {
                        id: pageButtons
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.xs

                        IconButton {
                            icon: "close_fullscreen"
                            label: "Smaller (Ctrl + Down)"
                            enabled: LauncherState.size !== "compact"
                            opacity: enabled ? 1 : Theme.state.disabled
                            onClicked: LauncherState.resize(-1)
                        }

                        IconButton {
                            icon: "open_in_full"
                            label: "Larger (Ctrl + Up)"
                            enabled: LauncherState.size !== "full"
                            opacity: enabled ? 1 : Theme.state.disabled
                            onClicked: LauncherState.resize(1)
                        }

                        IconButton {
                            icon: "close"
                            label: "Close"
                            onClicked: LauncherState.open = false
                        }
                    }
                }

                Item {
                    anchors.top: pageHeader.bottom
                    anchors.topMargin: Theme.spacing.m
                    anchors.bottom: parent.bottom
                    width: parent.width

                    // Built while it's the page (its pages are built as they're chosen).
                    Loader {
                        id: settingsLoader
                        anchors.fill: parent
                        active: root.page === "settings"
                        sourceComponent: SettingsView {
                            compact: LauncherState.size === "compact"
                        }
                    }

                    // Kept for as long as the shell runs: its results and downloads stay.
                    WallpaperBrowser {
                        anchors.fill: parent
                        visible: root.page === "wallpapers"
                        active: visible && window.visible
                    }
                }
            }
        }
    }

    // Super+U: the customize tiles have the keyboard.
    function customizeFocus(): void {
        if (LauncherState.customize && root.page === "")
            tiles.itemAt(0)?.forceActiveFocus(Qt.TabFocusReason);
        else
            search.focusInput();
    }
}
