import QtQuick
import QtTest
import "../quickshell/.config/quickshell/theme/ThemeScale.js" as ThemeScale

TestCase {
    name: "ThemeScale"

    function test_pick() {
        compare(ThemeScale.pick(1.25, ThemeScale.sizes), 1.25);
        compare(ThemeScale.pick(3, ThemeScale.sizes), 1);
        compare(ThemeScale.pick("1.1", ThemeScale.textSizes), 1);
        compare(ThemeScale.pick(undefined, ThemeScale.corners), 1);
        compare(ThemeScale.pick(0, ThemeScale.corners), 0);
        // With a fallback: the setting's own default.
        compare(ThemeScale.pick(99, ThemeScale.dockIcons, 44), 44);
        compare(ThemeScale.pick(0, ThemeScale.workspaceDots, 5), 0);
        compare(ThemeScale.pick(undefined, ThemeScale.launcherRows, 8), 8);
    }

    function test_px() {
        compare(ThemeScale.px(16, 1), 16);
        compare(ThemeScale.px(16, 1.25), 20);
        compare(ThemeScale.px(13, 0.85), 11);
        compare(ThemeScale.px(1, 0.85), 1);
    }

    function test_radius() {
        compare(ThemeScale.radius(20, 1, 1), 20);
        compare(ThemeScale.radius(20, 1.1, 0.5), 11);
        compare(ThemeScale.radius(20, 1, 0), 0);
        compare(ThemeScale.radius(999, 1.25, 1), 999);
        compare(ThemeScale.radius(999, 1, 0), 0);
    }
}
