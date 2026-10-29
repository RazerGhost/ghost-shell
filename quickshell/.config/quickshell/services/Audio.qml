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
    // An app records from the microphone while it's muted: talking into a call that can't hear
    // you (the OSD warns, the island's mic icon turns red).
    readonly property bool mutedWhileRecording: micMuted && recordingApps.length > 0

    // The apps recording from the microphone right now, by name (like the microphone indicator
    // on Android and macOS): the app streams linked to the default microphone. The shell itself
    // never counts.
    readonly property list<string> recordingApps: {
        const names = [];
        for (const group of micLinks.linkGroups) {
            const node = group?.target;
            if (!node?.isStream)
                continue;
            const name = node.properties["application.name"] || node.description || node.name || "";
            if (name && !/quickshell/i.test(name) && !names.includes(name))
                names.push(name);
        }
        return names;
    }

    PwNodeLinkTracker {
        id: micLinks
        node: Pipewire.defaultAudioSource
    }

    // PipeWire only fills in a node's details (its app name) while something tracks it.
    PwObjectTracker {
        objects: micLinks.linkGroups.map(g => g?.target).filter(n => n)
    }

    readonly property string icon: muted || volume === 0 ? "volume_off"
                                 : volume < 0.5 ? "volume_down"
                                 : "volume_up"

    // A short name for a speaker or microphone. Built-in sound cards have long names ("Ryzen HD
    // Audio Controller Speaker") but a short profile name ("Speaker"); Bluetooth devices only
    // have their own name, which is short already. The node must be tracked (PwObjectTracker).
    function deviceName(node: PwNode): string {
        return node?.properties["device.profile.description"] || node?.description || node?.nickname || node?.name || "";
    }

    // Headphones and headsets by name ("Headphones", "WH-1000XM4 Headset"), anything else a speaker.
    function deviceIcon(node: PwNode): string {
        return deviceName(node).toLowerCase().includes("head") ? "headphones" : "speaker";
    }

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
