// The camera and screen sharing, like the microphone indicator (Audio.recordingApps): the
// island shows an icon while they're in use and quick settings says by whom.
// - Camera: services/camera.sh every 3 s (a sysfs read; the apps are looked up only while it's in
//   use). Parsed by Privacy.js (tested).
// - Screen sharing: xdg-desktop-portal-hyprland's PipeWire stream ("xdph-streaming-<n>") exists
//   while an app shares the screen or a window through the portal. Matched by node name: reading
//   node properties in a binding loops (see NOTES.md). The shell's own previews and grim don't
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
    readonly property bool screenShared: (Pipewire.nodes?.values ?? []).some(n => n.name.startsWith("xdph-streaming-"))

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    Process {
        id: check
        command: ["sh", Quickshell.shellDir + "/services/camera.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const camera = PrivacyJs.camera(text);
                root.cameraInUse = camera.inUse;
                root.cameraApps = camera.apps;
            }
        }
    }
}
