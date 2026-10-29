import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "Fuzzy.js" as Fuzzy
import "../settings/Keybinds.js" as Keybinds

// App launcher: type to fuzzy-search installed apps and open windows, arrow keys to pick, Enter
// to launch or switch, Escape or a click outside to close. "/ name" searches files in the home
// folder (fd) and "> command" runs a command in the terminal (Fuzzy.mode, tested). Toggled with
// `qs ipc call launcher toggle` (tap Super or Super+Space).
Scope {
    id: root

    // The shell's own entries, found like your commands: the on-screen editors (customize/).
    readonly property var shellCommands: [
        { name: "Customize the lock screen", command: "qs ipc call customize lock",
          icon: "preferences-desktop-screensaver", subtitle: "Its clock, picture and look, on the screen itself" },
        { name: "Customize the desktop", command: "qs ipc call customize desktop",
          icon: "preferences-desktop-wallpaper", subtitle: "Wallpaper, colors, widgets and style, on the desktop itself" }
    ]

    property bool open: false

    // A result: an app or one of its shortcuts ({ entry, action }; action null for the app), a
    // window ({ window }), a file ({ file }), a command to run ({ command }), a web search
    // ({ web }: DuckDuckGo in the default browser), a color ({ color }: copied) or a keybind
    // ({ keybind }: just shown).
    function launch(result: var): void {
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
        open = false;
    }

    function appResults(text: string): var {
        const color = Fuzzy.color(text);
        const found = Fuzzy.results(DesktopEntries.applications.values, text,
                                    open && text.trim() !== "" ? windowList() : [],
                                    { favorites: Settings.values.launcherFavorites, hidden: Settings.values.launcherHidden,
                                      commands: Settings.values.launcherCommands.concat(root.shellCommands) });
        return (color ? [{ color: color }] : []).concat(found, text.trim() !== "" ? [{ web: text.trim() }] : []);
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
            root.open = !root.open;
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

    PanelWindow {
        id: window

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: root.open

        // No anchors: the compositor centers the surface on the screen.
        implicitWidth: Theme.launcher.width
        implicitHeight: panel.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

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
            onCleared: root.open = false
        }

        // Start fresh every time it opens.
        onVisibleChanged: {
            if (visible) {
                search.text = "";
                search.focusInput();
            }
        }

        Surface {
            id: panel

            width: parent.width
            implicitHeight: column.implicitHeight + Theme.spacing.m * 2
            radius: Theme.radius.m * 2

            Column {
                id: column

                anchors.fill: parent
                anchors.margins: Theme.spacing.m
                spacing: Theme.spacing.s

                SearchField {
                    id: search

                    readonly property var query: Fuzzy.mode(text)

                    width: parent.width
                    placeholder: "Search apps and windows,  / files,  > run,  ? keys"
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
                        switch (event.key) {
                        case Qt.Key_Escape:
                            root.open = false;
                            break;
                        case Qt.Key_Down:
                            if (calc.selected)
                                calc.selected = false;
                            else
                                list.incrementCurrentIndex();
                            break;
                        case Qt.Key_Up:
                            if (list.currentIndex === 0 && calc.answer !== "")
                                calc.selected = true;
                            else
                                list.decrementCurrentIndex();
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

                CalcRow {
                    id: calc
                    width: parent.width
                    current: search.text
                    onCopied: root.open = false
                }

                FileSearch {
                    id: fileSearch
                    current: search.query.mode === "files" ? search.query.text : ""
                }

                ListView {
                    id: list

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
                    visible: list.count === 0
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
        }
    }
}
