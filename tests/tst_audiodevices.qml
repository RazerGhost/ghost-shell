import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/AudioDevices.js" as AudioDevices

TestCase {
    name: "AudioDevices"

    function test_takesOver() {
        // USB-C IEMs (a DAC dongle): the sound and its microphone.
        verify(AudioDevices.takesOver("alsa_output.usb-LE_XIAN_SIMGOT_EW300_DSP_2024-07-03-0000-0000-0000-00.analog-stereo", true));
        verify(AudioDevices.takesOver("alsa_input.usb-LE_XIAN_SIMGOT_EW300_DSP_2024-07-03-0000-0000-0000-00.mono-fallback", false));
        // Bluetooth: the sound, never the microphone (it would drop music to call quality).
        verify(AudioDevices.takesOver("bluez_output.AC_80_0A_12_34_56.1", true));
        verify(!AudioDevices.takesOver("bluez_input.AC_80_0A_12_34_56.0", false));
        // The laptop's own card (the jack switches it by itself), HDMI, the equalizer, cameras.
        verify(!AudioDevices.takesOver("alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink", true));
        verify(!AudioDevices.takesOver("alsa_output.pci-0000_05_00.6.HiFi__Headphones__sink", true));
        verify(!AudioDevices.takesOver("alsa_input.pci-0000_05_00.6.HiFi__Mic1__source", false));
        verify(!AudioDevices.takesOver("alsa_output.pci-0000_01_00.1.hdmi-stereo", true));
        verify(!AudioDevices.takesOver("ghost-equalizer", true));
        verify(!AudioDevices.takesOver("v4l2_input.pci-0000_05_00.4-usb-0_1_1.0", false));
        // An output name asked about as a microphone, and nothing at all.
        verify(!AudioDevices.takesOver("alsa_output.usb-X.analog-stereo", false));
        verify(!AudioDevices.takesOver(undefined, true));
    }

    function test_label() {
        // The laptop's card: its short profile name.
        compare(AudioDevices.label("alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink",
            { "node.description": "Ryzen HD Audio Controller Speaker", "node.nick": "ALC245 Analog", "device.profile.description": "Speaker" }), "Speaker");
        // USB: the product, not "Analog Stereo".
        compare(AudioDevices.label("alsa_output.usb-LE_XIAN_SIMGOT_EW300_DSP-00.analog-stereo",
            { "node.description": "SIMGOT EW300 DSP Analog Stereo", "node.nick": "SIMGOT EW300 DSP", "device.profile.description": "Analog Stereo" }), "SIMGOT EW300 DSP");
        compare(AudioDevices.label("alsa_input.usb-X-00.mono-fallback", { "node.description": "X Mono" }), "X Mono");
        // Bluetooth: its own name.
        compare(AudioDevices.label("bluez_output.AC_80.1", { "node.description": "WH-1000XM4" }), "WH-1000XM4");
        // Not tracked yet: the node name.
        compare(AudioDevices.label("alsa_output.usb-X.analog-stereo", {}), "alsa_output.usb-X.analog-stereo");
        compare(AudioDevices.label(undefined, undefined), "");
    }

    function test_headphones() {
        verify(AudioDevices.headphones("alsa_output.usb-X.analog-stereo", "X"));
        verify(AudioDevices.headphones("bluez_output.AC_80.1", "WH-1000XM4"));
        verify(AudioDevices.headphones("alsa_output.pci-0000_05_00.6.HiFi__Headphones__sink", "Headphones"));
        verify(!AudioDevices.headphones("alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink", "Speaker"));
    }

    readonly property string out: "alsa_output.usb-LE_XIAN_SIMGOT_EW300_DSP-00.analog-stereo"
    readonly property string mic: "alsa_input.usb-LE_XIAN_SIMGOT_EW300_DSP-00.mono-fallback"
    readonly property string cam: "alsa_input.usb-Logitech_C920-02.analog-stereo"
    readonly property string wave: "alsa_input.usb-Elgato_Wave_3-00.mono-fallback"

    function test_deviceOf() {
        compare(AudioDevices.deviceOf(out), "usb-LE_XIAN_SIMGOT_EW300_DSP-00");
        compare(AudioDevices.deviceOf(mic), "usb-LE_XIAN_SIMGOT_EW300_DSP-00");
        compare(AudioDevices.deviceOf("alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink"), "");
    }

    function test_takeovers() {
        // A headset plugged in: its output and microphone, in either order.
        compare(AudioDevices.takeovers([out, mic], [out, mic], {}), { sink: out, source: mic });
        compare(AudioDevices.takeovers([out], [mic, out], {}), { sink: out, source: mic });   // the mic came first
        compare(AudioDevices.takeovers([mic], [mic, out], {}), { sink: "", source: mic });    // the mic came last
        // A webcam's or a Wave:3's microphone alone: nothing (picked by hand, WirePlumber keeps it).
        compare(AudioDevices.takeovers([cam], [cam], {}), { sink: "", source: "" });
        compare(AudioDevices.takeovers([wave], [wave], {}), { sink: "", source: "" });
        // Back after sleep: again only if it was in use when it left.
        compare(AudioDevices.takeovers([out, mic], [out, mic], { [out]: false, [mic]: false }), { sink: "", source: "" });
        compare(AudioDevices.takeovers([out, mic], [out, mic], { [out]: true, [mic]: true }), { sink: out, source: mic });
        // Bluetooth: the sound, never its microphone.
        compare(AudioDevices.takeovers(["bluez_output.AC.1", "bluez_input.AC.0"], ["bluez_output.AC.1", "bluez_input.AC.0"], {}),
                { sink: "bluez_output.AC.1", source: "" });
    }

    function test_listed() {
        const xlr = ["OpenXLR_ch_system", "OpenXLR_ch_game", "OpenXLR_mix_monitor", "OpenXLR_chat", "OpenXLR_stream",
                     "alsa_input.usb-Elgato_Systems_Elgato_Wave_3_A011-00.mono-fallback"];
        // openxlr's outputs: only its System channel; its mixes, other channels and inputs aren't.
        verify(AudioDevices.listed("OpenXLR_ch_system", true, xlr));
        verify(!AudioDevices.listed("OpenXLR_ch_game", true, xlr));
        verify(!AudioDevices.listed("OpenXLR_mix_monitor", true, xlr));
        verify(!AudioDevices.listed("OpenXLR_post_chat", true, xlr));
        verify(!AudioDevices.listed("OpenXLR_ch_xlr1", true, xlr));
        // Its microphones: the processed Chat and Stream, not its filters.
        verify(AudioDevices.listed("OpenXLR_chat", false, xlr));
        verify(AudioDevices.listed("OpenXLR_stream", false, xlr));
        verify(!AudioDevices.listed("OpenXLR_eq_xlr1_1", false, xlr));
        // The Wave:3's raw microphone: hidden while openxlr runs, listed without it.
        verify(!AudioDevices.listed(xlr[5], false, xlr));
        verify(AudioDevices.listed(xlr[5], false, [xlr[5]]));
        // Everything else stays: the Wave:3's headphone jack, other devices.
        verify(AudioDevices.listed("alsa_output.usb-Elgato_Systems_Elgato_Wave_3_A011-00.analog-stereo", true, xlr));
        verify(AudioDevices.listed(out, true, xlr));
        verify(AudioDevices.listed(cam, false, xlr));
        // A hidden microphone never takes over: the Wave:3 plugged in while openxlr runs gives
        // its output, not its raw microphone.
        const waveOut = "alsa_output.usb-Elgato_Systems_Elgato_Wave_3_A011-00.analog-stereo";
        compare(AudioDevices.takeovers([waveOut, xlr[5]], [waveOut, ...xlr], {}), { sink: waveOut, source: "" });
    }

    function test_added() {
        compare(AudioDevices.added(["a", "b"], ["a", "b", "c"]), ["c"]);
        compare(AudioDevices.added(["a", "b"], ["b"]), []);   // one went away: nothing new
        compare(AudioDevices.added([], ["a"]), ["a"]);
        compare(AudioDevices.added(undefined, ["a"]), ["a"]);
    }
}
