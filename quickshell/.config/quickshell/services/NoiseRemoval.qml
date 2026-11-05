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

    // Another microphone made the default while it's on (a headset plugged in, one picked in the
    // Sound page): that one stays when it goes off, rather than the one it started from.
    Connections {
        target: Audio
        function onSourceNameChanged(): void {
            if (root.on && root.cleaned && Audio.sourceName !== "" && Audio.sourceName !== NoiseRemovalJs.sourceName)
                root.previous = "";
        }
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

    // A filter left running (the shell crashed while it was on) would keep its microphone the
    // default while this says off, and a second one would start next to it: it goes first, at
    // start and before every start (pkill -x -f: exactly its command line).
    Process {
        running: true
        command: ["pkill", "-x", "-f", "pipewire -c " + root.configPath]
    }

    Process {
        id: filter
        command: ["sh", "-c", "pkill -x -f \"pipewire -c $0\"; exec pipewire -c \"$0\"", root.configPath]
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
