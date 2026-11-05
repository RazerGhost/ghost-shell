import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/NoiseRemoval.js" as NoiseRemoval

TestCase {
    name: "NoiseRemoval"

    function test_config() {
        const text = NoiseRemoval.config("alsa_input.pci-0000_05_00.6.HiFi__Mic1__source");
        verify(text.includes('target.object = "alsa_input.pci-0000_05_00.6.HiFi__Mic1__source"'));
        verify(text.includes('node.name = "ghost-noise-source"'));
        verify(text.includes("plugin = /usr/lib/ladspa/librnnoise_ladspa.so"));
        verify(text.includes("media.class = Audio/Source"));
        // Names that would break out of the config, none, or its own output: nothing.
        compare(NoiseRemoval.config('mic" } { name = x'), "");
        compare(NoiseRemoval.config(""), "");
        compare(NoiseRemoval.config(undefined), "");
        compare(NoiseRemoval.config("ghost-noise-source"), "");
    }
}
