pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "ScreenTime.js" as ScreenTimeJs

// Screen time (Settings -> Screen time): how long each app is in use per day. Every 10 s the
// focused window's app gets 10 s more, unless nothing has been touched for 2 minutes (a playing
// video or a game that keeps the screen on still counts: they hold an idle inhibitor). A locked
// screen and suspend count as nothing. Saved to ~/.local/state/quickshell/screentime.json once a
// minute; 30 days are kept. Across a shell reload the counts are carried over in memory, as
// JSON text (a JavaScript object can't move to the reloaded shell's engine): a write started
// while the shell reloads is cancelled.
Singleton {
    id: root

    readonly property int sample: 10 // seconds
    property var data: ({})
    property bool loaded: false

    function save(): void {
        if (persist.unsaved)
            file.setText(persist.json);
        persist.unsaved = false;
    }

    PersistentProperties {
        id: persist
        reloadableId: "screenTime"

        property string json: "" // `data`, kept up to date
        property bool unsaved: false

        onReloaded: {
            if (json !== "") {
                root.data = JSON.parse(json);
                root.loaded = true;
            }
        }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/screentime.json"
        printErrors: false // missing until the first minute is saved
        onLoaded: {
            if (root.loaded)
                return; // carried over from before a reload, which is newer
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                // Starting over would overwrite it at the next save: keep it for the user.
                console.warn("screentime.json isn't valid JSON, starting over (kept as screentime.json.bad):", e);
                Quickshell.execDetached(["cp", "-f", path, path + ".bad"]);
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    IdleMonitor {
        id: idle
        timeout: 120
    }

    Timer {
        running: root.loaded
        interval: root.sample * 1000
        repeat: true
        onTriggered: {
            const appId = Windows.active?.wayland?.appId ?? "";
            if (idle.isIdle || appId === "")
                return;
            // By desktop entry, so the page can show the app's name and icon.
            const app = DesktopEntries.heuristicLookup(appId)?.id ?? appId;
            root.data = ScreenTimeJs.add(root.data, ScreenTimeJs.day(new Date()), app, root.sample);
            persist.json = JSON.stringify(root.data);
            persist.unsaved = true;
        }
    }

    Timer {
        running: root.loaded
        interval: 60 * 1000
        repeat: true
        onTriggered: root.save()
    }
}
