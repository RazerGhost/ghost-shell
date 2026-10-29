import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "Fuzzy.js" as Fuzzy

// App launcher: type to fuzzy-search installed apps and open windows, arrow keys to pick, Enter
// to launch or switch, Escape or a click outside to close. "/ name" searches files in the home
// folder (fd) and "> command" runs a command in the terminal (Fuzzy.mode, tested). Toggled with
// `qs ipc call launcher toggle` (tap Super or Super+Space).
Scope {
    id: root

    property bool open: false

    // A result: an app or one of its shortcuts ({ entry, action }; action null for the app), a
    // window ({ window }), a file ({ file }) or a command to run ({ command }).
    function launch(result: var): void {
        if (result.window)
            Windows.show(result.window);
        else if (result.file)
            Quickshell.execDetached(["xdg-open", result.file.path]);
        else if (result.command)
            // The terminal stays open in your shell after the command, to read what it printed.
            Apps.runInTerminal(["sh", "-c", 'eval "$1"; exec "${SHELL:-sh}"', "sh", result.command]);
        else if (result.action)
            result.action.execute();
        else
            Apps.launch(result.entry);
        open = false;
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
                    placeholder: "Search apps and windows,  / files,  > run"
                    fontSize: Theme.font.large

                    // New results: select the best match again (the answer, while there is one).
                    onTextChanged: {
                        list.currentIndex = 0;
                        // From the text itself: `query` may not have caught up with it yet here,
                        // and a search for the text before the last key was thrown away as stale.
                        const now = Fuzzy.mode(text);
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
                              // Windows only while open with a query: their titles change all the time.
                              : Fuzzy.results(DesktopEntries.applications.values, search.text,
                                              root.open && search.query.text.trim() !== "" ? root.windowList() : [])
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
                        : "No apps found"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }
        }
    }
}
