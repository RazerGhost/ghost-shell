import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/NotificationRules.js" as Rules

TestCase {
    name: "NotificationRules"

    function test_mode() {
        const apps = { Vesktop: { mode: "always" }, Odd: { mode: "loud" } };
        compare(Rules.mode(apps, "Vesktop"), "always");
        compare(Rules.mode(apps, "Odd"), "normal"); // a hand-edited mode
        compare(Rules.mode(apps, "Unknown"), "normal");
        compare(Rules.mode(undefined, "x"), "normal");
    }

    function test_popsUp() {
        verify(Rules.popsUp("normal", false, false));
        verify(!Rules.popsUp("normal", true, false));
        verify(Rules.popsUp("always", true, false));
        verify(!Rules.popsUp("silent", false, false));
        verify(Rules.popsUp("silent", true, true)); // critical
    }

    function test_remember() {
        const apps = Rules.remember({}, "Zen");
        compare(apps, { Zen: { mode: "normal" } });
        compare(Rules.remember(apps, "Zen"), null);
        compare(Rules.remember(apps, ""), null);
        compare(Rules.withMode(apps, "Zen", "silent"), { Zen: { mode: "silent" } });
        compare(apps.Zen.mode, "normal"); // not changed in place
    }
}
