// Starting apps from their .desktop entries, shared by the launcher and the dock.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function launch(entry: DesktopEntry): void {
        // execute() ignores Terminal=true, so run those apps in Ghostty ourselves.
        // Keep the terminal in sync with `terminal` in hypr/binds.lua.
        if (entry.runInTerminal)
            Quickshell.execDetached(["ghostty", "-e", ...entry.command]);
        else
            entry.execute();
    }
}
