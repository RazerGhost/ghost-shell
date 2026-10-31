// Starting apps from their .desktop entries, shared by the launcher, the dock and the keybinds
// (through the "apps" IPC target in launcher/Launcher.qml). The default terminal, browser and
// file manager are chosen in Settings. Every app runs in its own systemd scope
// (`run`), so when memory runs out systemd-oomd closes that app, not the whole session.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // The .desktop categories an app needs to be offered as each kind of default app: all of
    // them; a nested list means any one of those (Decibels says Music, not Player).
    readonly property var categories: ({
        terminal: ["TerminalEmulator"],
        browser: ["WebBrowser"],
        fileManager: ["FileManager"],
        editor: ["TextEditor"],
        imageViewer: ["Graphics", "Viewer"],
        videoPlayer: ["Video", "Player"],
        audioPlayer: ["Audio", ["Player", "Music"]]
    })

    // The file types each kind becomes the system's default for (what other apps and Nautilus
    // open things with). The browser is set through xdg-settings instead (links and web pages).
    readonly property var fileTypes: ({
        fileManager: ["inode/directory"],
        editor: ["text/plain"],
        imageViewer: ["image/png", "image/jpeg", "image/gif", "image/webp", "image/bmp", "image/tiff",
                      "image/avif", "image/heic", "image/svg+xml", "image/x-icon"],
        videoPlayer: ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime", "video/x-msvideo",
                      "video/mpeg", "video/ogg", "video/x-flv", "video/3gpp"],
        audioPlayer: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-vorbis+ogg", "audio/opus",
                      "audio/wav", "audio/x-wav", "audio/mp4", "audio/aac", "audio/webm"]
    })

    function launch(entry: DesktopEntry): void {
        // execute() ignores Terminal=true, so run those apps in the terminal ourselves.
        if (entry.runInTerminal)
            runInTerminal(entry.command);
        else
            run(entry.command, entry.id, entry.workingDirectory);
    }

    // A .desktop action (a shortcut like "New private window") of `entry`.
    function launchAction(action: DesktopAction, entry: DesktopEntry): void {
        run(action.command, entry.id, entry.workingDirectory);
    }

    // Open a file, folder or link in its default app.
    function openPath(target: string): void {
        run(["xdg-open", target], "xdg-open", "");
    }

    // Start a command in its own systemd scope (hypr/run-app.sh: when memory runs out, oomd
    // closes that app rather than the whole session; and without the shell's Mesa-only EGL).
    readonly property string runApp: Quickshell.env("HOME") + "/.config/hypr/run-app.sh"

    function run(command: list<string>, id: string, workingDirectory: string): void {
        Quickshell.execDetached({
            command: [runApp, id, ...command],
            workingDirectory: workingDirectory || Quickshell.env("HOME")
        });
    }

    // The chosen app of a kind ("terminal", "browser", "editor", ...); null if it's not installed.
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
            run([...terminal.command, "-e", ...command], terminal.id, "");
        else
            console.warn(`Apps: no terminal installed with id "${Settings.values.terminal}"`);
    }

    // Installed apps that can be the default of a kind, by name.
    function candidates(kind: string): list<DesktopEntry> {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && categories[kind].every(c => Array.isArray(c) ? c.some(any => e.categories.includes(any))
                                                                                       : e.categories.includes(c)))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    // Choose the default app of a kind. Apart from the terminal, it also becomes the system's
    // default, for the links, folders, pictures, videos and music other apps open.
    function setDefault(kind: string, id: string): void {
        Settings.values[kind] = id;
        applySystemDefault(kind);
    }

    function applySystemDefault(kind: string): void {
        const id = Settings.values[kind];
        if (kind === "browser")
            Quickshell.execDetached(["xdg-settings", "set", "default-web-browser", id + ".desktop"]);
        else if (fileTypes[kind])
            Quickshell.execDetached(["xdg-mime", "default", id + ".desktop", ...fileTypes[kind]]);
    }

    // Make the system's defaults match the settings (shell.qml, once they're loaded): this is
    // the one place the file types are set, also on a new install. One after another in one
    // shell: xdg-mime processes running side by side overwrite each other's mimeapps.list.
    // The app ids go in as arguments ($1, $2, ...), not into the script text.
    function applySystemDefaults(): void {
        const kinds = Object.keys(fileTypes);
        const lines = ['xdg-settings set default-web-browser "$1.desktop"'];
        kinds.forEach((kind, i) => lines.push(`xdg-mime default "$${i + 2}.desktop" ${fileTypes[kind].join(" ")}`));
        Quickshell.execDetached(["sh", "-c", lines.join("\n"), "sh", Settings.values.browser,
                                 ...kinds.map(kind => Settings.values[kind])]);
    }
}
