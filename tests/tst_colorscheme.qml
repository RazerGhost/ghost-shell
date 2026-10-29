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

    function test_file() {
        compare(ColorScheme.file("light", "scheme-vibrant", 0.5, "#1E66F5"),
                "mode=light\ntype=scheme-vibrant\ncontrast=0.5\naccent=#1e66f5\n");
        // Hand-edited nonsense falls back to the defaults.
        compare(ColorScheme.file("purple", "$(rm -rf ~)", 7, "red; reboot"),
                "mode=dark\ntype=scheme-tonal-spot\ncontrast=1\naccent=\n");
        compare(ColorScheme.file("dark", undefined, undefined, undefined),
                "mode=dark\ntype=scheme-tonal-spot\ncontrast=0\naccent=\n");
    }
}
