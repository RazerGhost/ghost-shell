// Starting apps from their .desktop entries, shared by the launcher, the dock and the keybinds
// (through the "apps" IPC target in launcher/Launcher.qml). The default terminal, browser and
// file manager are chosen in the settings window.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // The .desktop categories an app needs to be offered as each kind of default app.
    readonly property var categories: ({
        terminal: ["TerminalEmulator"],
        browser: ["WebBrowser"],
        fileManager: ["FileManager"],
        imageViewer: ["Graphics", "Viewer"]
    })

    // The picture types the image viewer opens (screenshots, pictures in Nautilus).
    readonly property list<string> imageTypes: ["image/png", "image/jpeg", "image/gif", "image/webp",
        "image/bmp", "image/tiff", "image/avif", "image/heic", "image/svg+xml", "image/x-icon"]

    function launch(entry: DesktopEntry): void {
        // execute() ignores Terminal=true, so run those apps in the terminal ourselves.
        if (entry.runInTerminal)
            runInTerminal(entry.command);
        else
            entry.execute();
    }

    // The chosen app of a kind ("terminal", "browser", "fileManager"); null if it's not installed.
    function defaultApp(kind: string): DesktopEntry {
        return DesktopEntries.byId(Settings.values[kind]);
    }

    function open(kind: string): void {
        const entry = defaultApp(kind);
        if (entry)
            launch(entry);
        else
            console.warn(`Apps: no ${kind} installed with id "${Settings.values[kind]}"`);
    }

    // `-e` runs a command in Ghostty, Kitty, Alacritty, Konsole and GNOME Console alike.
    function runInTerminal(command: list<string>): void {
        const terminal = defaultApp("terminal");
        if (terminal)
            Quickshell.execDetached([...terminal.command, "-e", ...command]);
        else
            console.warn(`Apps: no terminal installed with id "${Settings.values.terminal}"`);
    }

    // Installed apps that can be the default of a kind, by name.
    function candidates(kind: string): list<DesktopEntry> {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && categories[kind].every(c => e.categories.includes(c)))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    // Choose the default app of a kind. The browser, file manager and image viewer also become
    // the system's defaults, for the links, folders and pictures other apps open.
    function setDefault(kind: string, id: string): void {
        Settings.values[kind] = id;
        if (kind === "browser")
            Quickshell.execDetached(["xdg-settings", "set", "default-web-browser", id + ".desktop"]);
        else if (kind === "fileManager")
            Quickshell.execDetached(["xdg-mime", "default", id + ".desktop", "inode/directory"]);
        else if (kind === "imageViewer")
            Quickshell.execDetached(["xdg-mime", "default", id + ".desktop", ...imageTypes]);
    }
}
