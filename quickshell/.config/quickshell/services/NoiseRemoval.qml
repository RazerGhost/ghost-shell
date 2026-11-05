// Microphone noise removal (quick settings' round button): RNNoise cleans up the microphone
// (keyboard, fan, voices in the room) for calls and recordings. On: a config naming the
// microphone in use now is written to $XDG_RUNTIME_DIR (NoiseRemoval.js) and run as its own
// PipeWire client (`pipewire -c`), and its "Noise-cancelled microphone" becomes the default. Off,
// or the filter stopping: your microphone is the default again. Not kept across a shell
// restart (the filter stops with the shell). Needs noise-suppression-for-voice (core module).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "NoiseRemoval.js" as NoiseRemovalJs

Singleton {
    id: root

    property bool installed: false
    readonly property bool on: filter.running
    // The microphone to come back to (its node name).
    property string previous: ""
    readonly property string configPath: Quickshell.env("XDG_RUNTIME_DIR") + "/ghost-noise.conf"
    // The cleaned microphone, once PipeWire has it.
    readonly property PwNode cleaned: Audio.inputs.find(n => n.name === NoiseRemovalJs.sourceName) ?? null

    function toggle(): void {
        if (on) {
            filter.running = false;
            return;
        }
        const mic = Audio.source?.name ?? "";
        const text = NoiseRemovalJs.config(mic);
        if (!installed || text === "")
            return;
        previous = mic;
        configFile.setText(text);
        filter.running = true;
    }

    // Once the cleaned microphone is there, it's the default; when it goes, yours is again.
    onCleanedChanged: {
        if (cleaned) {
            Pipewire.preferredDefaultAudioSource = cleaned;
        } else if (previous !== "") {
            const mic = Audio.inputs.find(n => n.name === previous);
            if (mic)
                Pipewire.preferredDefaultAudioSource = mic;
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        blockWrites: true // written before the filter starts reading it
    }

    Process {
        id: filter
        command: ["pipewire", "-c", root.configPath]
        onExited: code => {
            if (code !== 0 && code !== 143)
                Notifications.send("Noise removal", "audio-input-microphone", "Noise removal stopped",
                                   "The filter couldn't run (exit " + code + ")", false, []);
        }
    }

    Process {
        running: true
        command: ["test", "-r", NoiseRemovalJs.plugin]
        onExited: code => root.installed = code === 0
    }
}
