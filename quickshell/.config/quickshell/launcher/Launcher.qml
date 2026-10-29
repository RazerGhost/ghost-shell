import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "Fuzzy.js" as Fuzzy
import "Calc.js" as Calc

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
                        calc.ask(query.mode === "apps" ? text : "");
                        if (query.mode === "files")
                            fileSearch.ask(query.text);
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

                // The calculator: a sum or a unit conversion typed into the search ("5 km in
                // miles", "20 usd to eur") answered by qalc (Calc.js, tested). Selected while it
                // shows; Enter copies the answer.
                MouseArea {
                    id: calc

                    property string answer: ""
                    property bool selected: false
                    property string asked: ""

                    function ask(query: string): void {
                        if (!Calc.isExpression(query)) {
                            answer = "";
                            selected = false;
                            return;
                        }
                        asked = query;
                        wait.restart();
                    }

                    function copy(): void {
                        Quickshell.execDetached(["wl-copy", answer]);
                        root.open = false;
                    }

                    width: parent.width
                    height: Theme.launcher.rowHeight
                    visible: answer !== ""
                    onAnswerChanged: selected = answer !== ""
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: copy()

                    Accessible.role: Accessible.Button
                    Accessible.name: "Result: " + answer + ", press Enter to copy"
                    Accessible.onPressAction: copy()

                    // After typing pauses, so qalc doesn't run for every key.
                    Timer {
                        id: wait
                        interval: 150
                        onTriggered: qalc.running = true
                    }

                    Process {
                        id: qalc
                        // Dots for decimals whatever the regional format.
                        command: ["qalc", "-s", "decimal comma off", "-t", Calc.prepare(calc.asked)]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                // An answer to an older question: the search changed since.
                                if (calc.asked === search.text)
                                    calc.answer = Calc.answer(text, calc.asked);
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius.m
                        color: Colors.m3surfaceContainerHighest
                        visible: calc.selected || calc.containsMouse
                    }

                    MaterialIcon {
                        id: calcIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.s + (Theme.icon.launcher - width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "calculate"
                        color: Colors.m3primary
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.s + Theme.icon.launcher + Theme.spacing.m
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "= " + calc.answer
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Enter copies the result"
                            color: Colors.m3onSurfaceVariant
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.small
                        }
                    }
                }

                // Files in the home folder for "/ name": fd (hidden and git-ignored files are left
                // out), once typing pauses. Parsed and sorted by Fuzzy.files (tested).
                Item {
                    id: fileSearch

                    property var found: []
                    property string asked: ""

                    function ask(text: string): void {
                        asked = text;
                        found = [];
                        if (text !== "")
                            waitFiles.restart();
                    }

                    Timer {
                        id: waitFiles
                        interval: 200
                        onTriggered: fd.running = true
                    }

                    Process {
                        id: fd
                        command: ["fd", "--absolute-path", "--ignore-case", "--fixed-strings", "--max-results", "50",
                                  "--", fileSearch.asked, Quickshell.env("HOME")]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                // Results for an older search: the text changed since.
                                if (search.query.mode === "files" && search.query.text === fileSearch.asked)
                                    fileSearch.found = Fuzzy.files(text, Quickshell.env("HOME"));
                            }
                        }
                    }
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
                              : Fuzzy.results(DesktopEntries.applications.values, search.text, root.windowList())
                    }
                    highlightMoveDuration: Theme.anim.fast
                    boundsBehavior: Flickable.StopAtBounds

                    Accessible.role: Accessible.List

                    highlight: Rectangle {
                        radius: Theme.radius.m
                        color: Colors.m3surfaceContainerHighest
                        visible: !calc.selected // the calculator's answer is selected instead
                    }

                    delegate: MouseArea {
                        id: row

                        required property var modelData // see root.launch()
                        required property int index
                        readonly property DesktopEntry entry: modelData.entry ?? null
                        readonly property string title: modelData.window ? modelData.window.title
                            : modelData.file ? modelData.file.name
                            : modelData.command ? modelData.command
                            : modelData.action?.name ?? entry?.name ?? ""
                        // For a shortcut, the app it belongs to.
                        readonly property string subtitle: modelData.window ? "Open window"
                            : modelData.file ? modelData.file.folder
                            : modelData.command ? "Run in the terminal"
                            : modelData.action ? entry.name : entry?.genericName || entry?.comment || ""
                        readonly property string icon: modelData.window ? Windows.iconFor(modelData.window)
                            : modelData.file ? Fuzzy.fileIcon(modelData.file.name)
                            : modelData.command ? "utilities-terminal"
                            : entry?.icon ?? ""

                        width: ListView.view.width
                        height: Theme.launcher.rowHeight
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = index
                        onClicked: root.launch(modelData)

                        Accessible.role: Accessible.ListItem
                        Accessible.name: subtitle !== "" ? title + ", " + subtitle : title
                        Accessible.onPressAction: root.launch(modelData)

                        IconImage {
                            id: appIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacing.s
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Theme.icon.launcher
                            // Falls back to a generic icon when the theme has no match.
                            source: Quickshell.iconPath(row.icon, "application-x-executable")
                        }

                        Column {
                            anchors.left: appIcon.right
                            anchors.right: parent.right
                            anchors.leftMargin: Theme.spacing.m
                            anchors.rightMargin: Theme.spacing.s
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                text: row.title
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.normal
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: row.subtitle
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    visible: list.count === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spacing.s
                    bottomPadding: Theme.spacing.s
                    text: search.query.mode === "files" ? (search.query.text === "" ? "Type a file or folder name" : fd.running || waitFiles.running ? "Searching…" : "No files found")
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
