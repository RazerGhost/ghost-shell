// The camera and screen sharing, like the microphone indicator (Audio.recordingApps): the
// island shows an icon while they're in use and quick settings says by whom.
// - Camera: its USB power state, read in-process every 3 s (the folders come from
//   services/camera.sh once at start; a camera plugged in later isn't seen until a restart).
//   Only while it's on does camera.sh name the apps holding it. Privacy.js, tested.
// - Screen sharing: xdg-desktop-portal-hyprland's PipeWire stream exists while an app shares the
//   screen or a window through the portal; xdph 1.5 names the node "xdg-desktop-portal-hyprland"
//   (older ones "xdph-streaming-<n>"). Matched by node name: reading node properties in a binding
//   loops (see NOTES.md). The shell's own previews and grim don't
//   go through the portal, so they don't count.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "Privacy.js" as PrivacyJs

Singleton {
    id: root

    property bool cameraInUse: false
    property var cameraApps: []
    readonly property bool screenShared: (Pipewire.nodes?.values ?? []).some(n => n.name === "xdg-desktop-portal-hyprland" || n.name.startsWith("xdph-streaming-"))

    // The cameras' device folders, once.
    property var cameraDirs: []

    Process {
        command: ["sh", Quickshell.shellDir + "/services/camera.sh", "devices"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cameraDirs = text.split("\n").filter(l => l !== "")
        }
    }

    Instantiator {
        id: cameraStates
        model: root.cameraDirs

        FileView {
            required property string modelData
            path: modelData + "/power/runtime_status"
            blockLoading: true // read right away in the timer
        }
    }

    Timer {
        interval: 3000
        running: root.cameraDirs.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const states = [];
            for (let i = 0; i < cameraStates.count; i++) {
                const state = cameraStates.objectAt(i);
                state.reload();
                states.push(state.text());
            }
            root.cameraInUse = PrivacyJs.inUse(states);
            if (root.cameraInUse)
                appsCheck.running = true;
            else
                root.cameraApps = [];
        }
    }

    Process {
        id: appsCheck
        command: ["sh", Quickshell.shellDir + "/services/camera.sh", "apps"]
        stdout: StdioCollector {
            onStreamFinished: root.cameraApps = PrivacyJs.apps(text)
        }
    }
}
