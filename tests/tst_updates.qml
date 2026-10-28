import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Updates.js" as Updates

TestCase {
    name: "Updates"

    function test_parse() {
        const text = [
            "linux-cachyos 6.17.1-1 -> 6.17.2-1",
            "mesa 1:25.2.4-1 -> 1:25.2.5-1",
            "--- aur",
            "zen-browser-bin 1.23.4b-1 -> 1.23.5b-1",
            ":: warning: something paru says", // not a package line
            ""
        ].join("\n");
        compare(Updates.parse(text), { repo: ["linux-cachyos", "mesa"], aur: ["zen-browser-bin"] });
        compare(Updates.parse("--- aur\n"), { repo: [], aur: [] });
    }

    function test_summary() {
        compare(Updates.summary(0, 0), "");
        compare(Updates.summary(1, 0), "1 update");
        compare(Updates.summary(9, 3), "12 updates · 3 from the AUR");
    }
}
