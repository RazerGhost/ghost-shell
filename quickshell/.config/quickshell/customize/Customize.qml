import QtQuick
import Quickshell
import Quickshell.Io

// The on-screen editors (user's choice over pickers inside Settings: Android's customization
// with iOS's and macOS's way of editing on the screen itself). Opened from Settings and the
// launcher: `qs ipc call customize lock|desktop|dock|windows`; `close` closes an open one, keeping its
// changes.
Scope {
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

    IpcHandler {
        target: "customize"

        function lock(): void {
            lockEditor.open();
        }

        function desktop(): void {
            desktopEditor.open();
        }

        function dock(): void {
            dockIslandEditor.open();
        }

        function windows(): void {
            windowsEditor.open();
        }

        function close(): void {
            lockEditor.close();
            desktopEditor.close();
            dockIslandEditor.close();
            windowsEditor.close();
        }
    }
}
