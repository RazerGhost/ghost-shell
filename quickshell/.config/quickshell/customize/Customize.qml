import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "LooksFile.js" as LooksFile

// The on-screen editors (user's choice over pickers inside Settings: Android's customization
// with iOS's and macOS's way of editing on the screen itself). Opened from the launcher's
// customize tiles (Super+U), Settings and the launcher's search:
// `qs ipc call customize menu|desktop|dock|windows|quick`; `close` closes an open one, keeping its
// changes.
Scope {
    id: root

    DesktopEditor {
        id: desktopEditor
    }

    DockIslandEditor {
        id: dockIslandEditor
    }

    WindowsEditor {
        id: windowsEditor
    }

    function closeAll(): void {
        desktopEditor.close();
        dockIslandEditor.close();
        windowsEditor.close();
    }

    // One editor at a time: they share Editing (the trip to an empty workspace, the card), so
    // opening one closes any other, keeping its changes.
    function only(editor: var): void {
        LauncherState.open = false; // a Customize button in Settings, or a tile, opened it
        for (const other of [desktopEditor, dockIslandEditor, windowsEditor])
            if (other !== editor)
                other.close();
        editor.open();
    }

    // Themes and looks from another machine (`ghost looks import`, the Themes tab's Import):
    // merged into the settings here, which this shell owns while it runs.
    Process {
        id: looksRead
        property string from
        command: ["cat", from]
        onExited: code => {
            if (code !== 0)
                Notifications.send("Customize", "dialog-warning", "Couldn't import the looks",
                                   looksRead.from + " couldn't be read.", false, []);
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text === "")
                    return;
                let file;
                try {
                    file = JSON.parse(text);
                } catch (e) {
                    Notifications.send("Customize", "dialog-warning", "Couldn't import the looks",
                                       looksRead.from + " isn't valid JSON.", false, []);
                    return;
                }
                const here = {};
                for (const key of LooksFile.keys)
                    here[key] = Array.from(Settings.values[key] ?? []);
                const merged = LooksFile.imported(here, file, Quickshell.env("HOME"));
                for (const key of LooksFile.keys)
                    Settings.values[key] = merged[key];
                // An editor open now keeps them through its Cancel: they're part of its "before".
                for (const editor of [desktopEditor, dockIslandEditor, windowsEditor]) {
                    const before = Object.assign({}, editor.saved);
                    for (const key of LooksFile.keys)
                        if (key in before)
                            before[key] = merged[key];
                    editor.saved = before;
                }
                const count = LooksFile.count(file);
                Notifications.send("Customize", "preferences-desktop-theme", "Looks imported",
                                   count + " themes and looks from your dotfiles, merged with this machine's.", false, []);
            }
        }
    }

    IpcHandler {
        target: "customize"

        function importLooks(path: string): void {
            // One at a time: a second while the first reads would rename what the notice names.
            if (looksRead.running)
                return;
            looksRead.from = path;
            looksRead.running = true;
        }

        // Super+U: open, or close again.
        // The customize tiles in the launcher (Super+U; they were a menu of their own).
        function menu(): void {
            LauncherState.showCustomize();
        }

        // Quick settings in its edit mode: no editor in front of it.
        function quick(): void {
            root.closeAll();
            Quickshell.execDetached(["qs", "ipc", "call", "island", "editQuickSettings"]);
        }

        function desktop(): void {
            root.only(desktopEditor);
        }

        function dock(): void {
            root.only(dockIslandEditor);
        }

        function windows(): void {
            root.only(windowsEditor);
        }

        function close(): void {
            root.closeAll();
        }
    }
}
