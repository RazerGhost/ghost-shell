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

    function test_added() {
        compare(AudioDevices.added(["a", "b"], ["a", "b", "c"]), ["c"]);
        compare(AudioDevices.added(["a", "b"], ["b"]), []);   // one went away: nothing new
        compare(AudioDevices.added([], ["a"]), ["a"]);
        compare(AudioDevices.added(undefined, ["a"]), ["a"]);
    }
}
