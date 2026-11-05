// The PipeWire config services/NoiseRemoval.qml runs (`pipewire -c`) for microphone noise
// removal: RNNoise (noise-suppression-for-voice's LADSPA plugin) between your microphone, named
// when it's switched on, and a new microphone, "Noise-cancelled microphone", which then becomes
// the default. A config of its own rather than one always loaded: a filter fed by the default
// microphone that becomes the default would feed itself. Plain JavaScript, tested
// (tests/tst_noiseremoval.qml).
.pragma library

const plugin = "/usr/lib/ladspa/librnnoise_ladspa.so";
const sourceName = "ghost-noise-source";

// The config for microphone `mic` (a PipeWire node name), or "" for a name that isn't safe to
// write into it.
function config(mic) {
    const name = String(mic ?? "");
    if (!/^[A-Za-z0-9_.:-]+$/.test(name) || name === sourceName)
        return "";
    return `# Written by the shell (services/NoiseRemoval.qml) while noise removal is on.
context.properties = { log.level = 0 }
context.spa-libs = {
    audio.convert.* = audioconvert/libspa-audioconvert
    support.*       = support/libspa-support
}
context.modules = [
    { name = libpipewire-module-rt args = { } flags = [ ifexists nofail ] }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-filter-chain
        args = {
            node.description = "Noise-cancelled microphone"
            media.name       = "Noise-cancelled microphone"
            filter.graph = {
                nodes = [
                    { type = ladspa name = rnnoise plugin = ${plugin} label = noise_suppressor_mono
                      control = { "VAD Threshold (%)" = 50.0 "VAD Grace Period (ms)" = 200 "Retroactive VAD Grace (ms)" = 0 } }
                ]
            }
            capture.props = {
                node.name = "ghost-noise-capture"
                target.object = "${name}"
                node.dont-reconnect = true
                node.passive = true
                audio.rate = 48000
                audio.channels = 1
            }
            playback.props = {
                node.name = "${sourceName}"
                media.class = Audio/Source
                audio.rate = 48000
                audio.channels = 1
            }
        }
    }
]
`;
}
