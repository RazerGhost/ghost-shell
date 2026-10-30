import QtQuick
import QtTest
import "../quickshell/.config/quickshell/desktop/DesktopWidgets.js" as DesktopWidgets

TestCase {
    name: "DesktopWidgets"

    function test_place() {
        compare(DesktopWidgets.place({}, "clock"), { x: 0.04, y: 0.08 });
        compare(DesktopWidgets.place({ clock: { x: 0.5, y: 0.25 } }, "clock"), { x: 0.5, y: 0.25 });
        // Off the screen or not a number: the default for that coordinate.
        compare(DesktopWidgets.place({ weather: { x: 3, y: "0.1" } }, "weather"), { x: 0.04, y: 0.26 });
        compare(DesktopWidgets.place(undefined, "media"), { x: 0.04, y: 0.44 });
        // The defaults don't overlap: 168 px high widgets on a 1920 x 1080 screen, the medium
        // ones 352 px wide.
        const width = { clock: 352, weather: 168, media: 352, calendar: 352, battery: 168, todo: 352 };
        const rects = Object.keys(width).map(n => {
            const p = DesktopWidgets.place({}, n);
            return { n, x: p.x * 1920, y: p.y * 1080, w: width[n], h: 168 };
        });
        for (const a of rects)
            for (const b of rects)
                if (a !== b)
                    verify(a.x + a.w <= b.x || b.x + b.w <= a.x || a.y + a.h <= b.y || b.y + b.h <= a.y, a.n + " " + b.n);
    }

    function test_dropped() {
        compare(DesktopWidgets.dropped(960, 540, 200, 100, 1920, 1080), { x: 0.5, y: 0.5 });
        // Past the right and bottom edges: pulled back so the whole widget shows.
        compare(DesktopWidgets.dropped(1900, 1070, 192, 108, 1920, 1080), { x: 0.9, y: 0.9 });
        compare(DesktopWidgets.dropped(-50, -10, 100, 100, 1000, 1000), { x: 0, y: 0 });
    }

    function test_withPlace() {
        const saved = { clock: { x: 0.5, y: 0.5 } };
        const places = DesktopWidgets.withPlace(saved, "weather", { x: 0.1, y: 0.2 });
        // The others stay, the original isn't changed.
        compare(places, { clock: { x: 0.5, y: 0.5 }, weather: { x: 0.1, y: 0.2 } });
        compare(saved, { clock: { x: 0.5, y: 0.5 } });
        compare(DesktopWidgets.withPlace(undefined, "media", { x: 0, y: 1 }), { media: { x: 0, y: 1 } });
    }

    function test_snapped() {
        // Near the top-left corner: onto the screen's margin.
        compare(DesktopWidgets.snapped(40, 20, 100, 50, 1920, 1080, [], 32, 16, 24), { x: 32, y: 32 });
        // Near the right and bottom edges.
        compare(DesktopWidgets.snapped(1800, 1000, 100, 50, 1920, 1080, [], 32, 16, 24), { x: 1788, y: 998 });
        // Far from everything: where it was dropped.
        compare(DesktopWidgets.snapped(500, 400, 100, 50, 1920, 1080, [], 32, 16, 24), { x: 500, y: 400 });
        // Under another widget: its left edge, and the gap below it.
        const other = { x: 300, y: 200, w: 200, h: 100 };
        compare(DesktopWidgets.snapped(310, 322, 100, 50, 1920, 1080, [other], 32, 16, 24), { x: 300, y: 316 });
        // Beside it: the gap to its right, and its top.
        compare(DesktopWidgets.snapped(520, 190, 100, 50, 1920, 1080, [other], 32, 16, 24), { x: 516, y: 200 });
    }
}
