import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/WifiQr.js" as WifiQr

TestCase {
    name: "WifiQr"

    function test_text() {
        compare(WifiQr.text("Home", "hunter22"), "WIFI:T:WPA;S:Home;P:hunter22;;");
        compare(WifiQr.text("Café", ""), "WIFI:T:nopass;S:Café;;");
        // Characters with a meaning in the format are escaped.
        compare(WifiQr.text("A;B", 'p:a"s\\s,w'), 'WIFI:T:WPA;S:A\\;B;P:p\\:a\\"s\\\\s\\,w;;');
    }
}
