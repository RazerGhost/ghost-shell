// Tests for reading hyprsunset's profile. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/NightLightProfile.js" as NightLightProfile

TestCase {
    name: "NightLightProfile"

    function test_evening() {
        verify(NightLightProfile.warm("Time: 20:00\nTemperature: 4000\nGamma: 1\nIdentity: false\n"));
    }

    function test_morningIdentity() {
        verify(!NightLightProfile.warm("Time: 7:00\nTemperature: 6000\nGamma: 1\nIdentity: true\n"));
    }

    function test_neutralTemperature() {
        verify(!NightLightProfile.warm("Time: 7:00\nTemperature: 6500\nGamma: 1\nIdentity: false\n"));
    }

    function test_garbageThrows() {
        let threw = false;
        try {
            NightLightProfile.warm("error: couldn't connect");
        } catch (e) {
            threw = true;
        }
        verify(threw);
    }
}
