pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "Equalizer.js" as EqualizerJs

// The equalizer between the apps and the speakers or headphones: PipeWire's filter-chain
// (filter-chain.service with ghost-equalizer.conf), whose gains this sets with pw-cli. Each
// output keeps its own (`equalizer` in settings.json, by PipeWire node name), applied when the
// output changes and again whenever the filter (re)starts, since it starts flat. An output with a
// profile of its own (the laptop's speakers, Equalizer.js `outputProfiles`) gets it after them.
Singleton {
    id: root

    readonly property var bands: EqualizerJs.bands
    readonly property var presets: EqualizerJs.presets
    readonly property int limit: EqualizerJs.limit

    readonly property PwNode device: Pipewire.defaultAudioSink
    readonly property var gains: EqualizerJs.gains(Settings.values.equalizer[device?.name ?? ""])
    readonly property string preset: EqualizerJs.presetName(gains)
    // False when filter-chain.service isn't running (the core module enables it).
    readonly property bool running: (Pipewire.nodes?.values ?? []).some(n => n.name === "ghost-equalizer")

    function setGains(gains: var): void {
        if (device)
            Settings.values.equalizer = Object.assign({}, Settings.values.equalizer, { [device.name]: gains });
    }

    function setBand(index: int, gain: real): void {
        const next = gains.slice();
        next[index] = gain;
        setGains(next);
    }

    function apply(): void {
        if (running)
            Quickshell.execDetached(["pw-cli", "set-param", "ghost-equalizer", "Props", EqualizerJs.props(gains, device?.name ?? "")]);
    }

    onGainsChanged: apply()
    // Another output has its own profile, even with the same five gains.
    onDeviceChanged: apply()
    onRunningChanged: apply()
}
