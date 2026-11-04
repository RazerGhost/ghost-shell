import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Equalizer.js" as Equalizer

TestCase {
    name: "Equalizer"

    function test_gains() {
        compare(Equalizer.gains([6, 3, 0, 0, 0]), [6, 3, 0, 0, 0]);
        // Lists read from settings.json aren't Arrays, only array-like.
        compare(Equalizer.gains({ length: 5, 0: 6, 1: 3, 2: 0, 3: 0, 4: 0 }), [6, 3, 0, 0, 0]);
        // Nothing saved, the wrong length, out of range or not numbers: flat.
        compare(Equalizer.gains(undefined), [0, 0, 0, 0, 0]);
        compare(Equalizer.gains([1, 2, 3]), [0, 0, 0, 0, 0]);
        compare(Equalizer.gains([20, 0, 0, 0, 0]), [0, 0, 0, 0, 0]);
        compare(Equalizer.gains(["6", 0, 0, 0, 0]), [0, 0, 0, 0, 0]);
    }

    function test_presetName() {
        compare(Equalizer.presetName([0, 0, 0, 0, 0]), "Off");
        compare(Equalizer.presetName([6, 3, 0, 0, 0]), "More bass");
        compare(Equalizer.presetName([6, 3, 0, 0, 1]), "Custom");
    }

    function test_props() {
        compare(Equalizer.props([6, -1.5, 0, 2, 1], "bluez_output.headphones"),
                '{ params = [ "bass:Gain" 6.0 "low_mids:Gain" -1.5 "mids:Gain" 0.0 "presence:Gain" 2.0 "treble:Gain" 1.0 "sp_preamp:Mult" 1.00 "sp_rumble:Freq" 10.0 "sp_punch:Gain" 0.0 "sp_body:Gain" 0.0 "sp_honk:Gain" 0.0 "sp_clarity:Gain" 0.0 "sp_air:Gain" 0.0 ] }');
        // Anything odd is sent as flat rather than as broken text.
        compare(Equalizer.props(["x"], ""),
                '{ params = [ "bass:Gain" 0.0 "low_mids:Gain" 0.0 "mids:Gain" 0.0 "presence:Gain" 0.0 "treble:Gain" 0.0 "sp_preamp:Mult" 1.00 "sp_rumble:Freq" 10.0 "sp_punch:Gain" 0.0 "sp_body:Gain" 0.0 "sp_honk:Gain" 0.0 "sp_clarity:Gain" 0.0 "sp_air:Gain" 0.0 ] }');
    }

    function test_outputProfile() {
        // The laptop's speakers get their profile after your bands; any other output the neutral one.
        const speakers = Equalizer.props([0, 0, 0, 0, 0], "alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink");
        verify(speakers.includes('"sp_preamp:Mult" 0.60'));
        verify(speakers.includes('"sp_honk:Gain" -5.0'));
        verify(speakers.includes('"sp_rumble:Freq" 90.0'));
        compare(Equalizer.profileFor("something else").rumble, 10);
    }
}
