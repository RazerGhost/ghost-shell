import QtQuick
import Quickshell
import Quickshell.Io

// The on-screen editors (user's choice over pickers inside Settings: Android's customization
// with iOS's and macOS's way of editing on the screen itself). Opened from the customize menu
// (Super+U, CustomizeMenu.qml), Settings and the launcher:
// `qs ipc call customize menu|lock|desktop|dock|windows`; `close` closes an open one, keeping its
// changes.
Scope {
    id: root

    LockEditor {
        id: lockEditor
    }

    DesktopEditor {
        id: desktopEditor
    }

    DockIslandEditor {
        id: dockIslandEditor
    }

    WindowsEditor {
        id: windowsEditor
    }

    CustomizeMenu {
        id: menu
        onPicked: id => {
            if (id !== "quick") {
                root.only(({ lock: lockEditor, desktop: desktopEditor, dock: dockIslandEditor, windows: windowsEditor })[id]);
                return;
            }
            // Quick settings is the island's: no editor in front of it.
            root.closeAll();
            Quickshell.execDetached(["qs", "ipc", "call", "island", "editQuickSettings"]);
        }
    }

    function closeAll(): void {
        lockEditor.close();
        desktopEditor.close();
        dockIslandEditor.close();
        windowsEditor.close();
    }

    // One editor at a time: they share Editing (the trip to an empty workspace, the card), so
    // opening one closes any other, keeping its changes.
    function only(editor: var): void {
        for (const other of [lockEditor, desktopEditor, dockIslandEditor, windowsEditor])
            if (other !== editor)
                other.close();
        editor.open();
    }

    IpcHandler {
        target: "customize"

        // Super+U: open, or close again.
        function menu(): void {
            menu.toggle();
        }

        function lock(): void {
            root.only(lockEditor);
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
