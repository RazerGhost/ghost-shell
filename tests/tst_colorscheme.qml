import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/ColorScheme.js" as ColorScheme

TestCase {
    name: "ColorScheme"

    function test_fixed() {
        compare(ColorScheme.mode("dark", 720, null, null), "dark");
        compare(ColorScheme.mode("light", 0, null, null), "light");
        compare(ColorScheme.mode("purple", 720, null, null), "dark");
    }

    function test_auto() {
        // Sunrise 07:45, sunset 17:21.
        compare(ColorScheme.mode("auto", 465, 465, 1041), "light");
        compare(ColorScheme.mode("auto", 1040, 465, 1041), "light");
        compare(ColorScheme.mode("auto", 1041, 465, 1041), "dark");
        compare(ColorScheme.mode("auto", 120, 465, 1041), "dark");
        // No weather town: 07:00-19:00.
        compare(ColorScheme.mode("auto", 1100, null, null), "light");
        compare(ColorScheme.mode("auto", 1140, null, null), "dark");
    }
}
