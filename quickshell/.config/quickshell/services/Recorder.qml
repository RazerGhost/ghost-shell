// Screen recording with gpu-screen-recorder (the capture module; hardware encoding on the AMD
// and NVIDIA GPUs): started from the screenshot tool's Record action, for a region, a window or
// a whole monitor; the island shows a red dot and the time while it runs. Saved to
// ~/Videos/Recordings (or Settings' folder) with the desktop's sound (and the microphone, if set), announced with a notification (click: play it).
// Stop it from quick settings, Super+Shift+R or `qs ipc call recorder stop`.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "CaptureFolders.js" as CaptureFolders

Singleton {
    id: root

    readonly property bool recording: recorder.running
    // Settings -> Screenshots and recordings (CaptureFolders.js, tested).
    readonly property string folder: CaptureFolders.folder(Settings.values.recordingFolder, Quickshell.env("HOME"),
                                                           Quickshell.env("HOME") + "/Videos/Recordings")
    property string file: ""
    property real startedAt: 0
    // Seconds since the start, updated every second while recording.
    property int elapsed: 0

    // "1:05", "12:40"
    readonly property string time: Math.floor(elapsed / 60) + ":" + String(elapsed % 60).padStart(2, "0")

    // `target`: a monitor's name ("eDP-1"), or "region" with `region` = { x, y, width, height }
    // in the monitor's pixels (global, like gpu-screen-recorder expects).
    function start(target: string, region: var): void {
        if (recording)
            return;
        file = folder + "/Recording_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
        // The settings' frame rate and quality preset, checked here (they come from a file).
        const fps = [30, 60].includes(Settings.values.recordingFps) ? Settings.values.recordingFps : 60;
        const quality = ["medium", "high", "very_high", "ultra"].includes(Settings.values.recordingQuality)
            ? Settings.values.recordingQuality : "very_high";
        const audio = Settings.values.recordingMic ? "default_output|default_input" : "default_output";
        const args = ["gpu-screen-recorder", "-w", target, "-f", String(fps), "-q", quality, "-a", audio, "-o", file];
        if (target === "region")
            args.splice(3, 0, "-region", `${Math.round(region.width)}x${Math.round(region.height)}+${Math.round(region.x)}+${Math.round(region.y)}`);
        recorder.command = ["sh", "-c", `mkdir -p "$1" && shift && exec "$@"`, "sh", folder, ...args];
        recorder.running = true;
        startedAt = Date.now();
        elapsed = 0;
    }

    // SIGINT: gpu-screen-recorder finishes the file and exits.
    function stop(): void {
        if (recording)
            recorder.signal(2);
    }

    Process {
        id: recorder
        onExited: code => {
            if (code === 0) {
                // The notification and its Play button: screenshot/capture.sh, like the screenshots'.
                Quickshell.execDetached(["sh", Quickshell.shellDir + "/screenshot/capture.sh", "recorded",
                                         root.file, CaptureFolders.short(root.folder, Quickshell.env("HOME"))]);
            } else {
                Quickshell.execDetached(["notify-send", "-a", "Recorder", "-u", "critical", "Recording failed",
                    "gpu-screen-recorder exited with code " + code]);
            }
        }
    }

    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }

    IpcHandler {
        target: "recorder"

        function stop(): void {
            root.stop();
        }

        function recording(): bool {
            return root.recording;
        }
    }
}
