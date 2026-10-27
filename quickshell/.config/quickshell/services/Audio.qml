// Default speaker and microphone from PipeWire, shared by the bar and the OSD.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // 0-1; volume can go above 1 when boosted, so the UI clamps where it draws a level.
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string icon: muted || volume === 0 ? "volume_off"
                                 : volume < 0.5 ? "volume_down"
                                 : "volume_up"

    // Matches the cap in the volume keybinds (wpctl -l 1).
    function setVolume(value: real): void {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // PipeWire only fills in a node's audio properties (volume, mute) while something
    // tracks it, so bind both default nodes here.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}
