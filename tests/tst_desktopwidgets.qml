import QtQuick
import QtTest
import "../quickshell/.config/quickshell/desktop/DesktopWidgets.js" as DesktopWidgets

TestCase {
    name: "DesktopWidgets"

    // Turned on, a widget goes where it's clear of the others at 100 % on 1920 x 1080.
    function test_freePlace() {
        // Its default place free: kept (the default is 0.04, 0.62 for notifications).
        compare(DesktopWidgets.freePlace({}, "notifications", [], 1920, 1080).notifications, { x: 0.04, y: 0.62 });
        // The clock (medium, 352 x 168) moved over its default: beside the clock, 16 px right.
        const saved = { clock: { x: 80 / 1920, y: 640 / 1080 } };
        compare(DesktopWidgets.freePlace(saved, "notifications", ["clock"], 1920, 1080).notifications,
                { x: Math.round((80 + 352 + 16) / 1920 * 10000) / 10000, y: Math.round(640 / 1080 * 10000) / 10000 });
        // Its own earlier place, still free, wins over the default.
        const own = { clock: saved.clock, notifications: { x: 0.5, y: 0.3 } };
        compare(DesktopWidgets.freePlace(own, "notifications", ["clock"], 1920, 1080).notifications, { x: 0.5, y: 0.3 });
        // The others keep their places, and the saved object isn't changed.
        const after = DesktopWidgets.freePlace(saved, "todo", ["clock"], 1920, 1080);
        compare(after.clock, saved.clock);
        verify(saved.todo === undefined);
        // Nowhere free (a tiny screen): as it was.
        compare(DesktopWidgets.freePlace(saved, "todo", ["clock"], 300, 300), saved);
    }

    function test_place() {
        compare(DesktopWidgets.place({}, "clock"), { x: 0.04, y: 0.08 });
        compare(DesktopWidgets.place({ clock: { x: 0.5, y: 0.25 } }, "clock"), { x: 0.5, y: 0.25 });
        // Off the screen or not a number: the default for that coordinate.
        compare(DesktopWidgets.place({ weather: { x: 3, y: "0.1" } }, "weather"), { x: 0.04, y: 0.26 });
        compare(DesktopWidgets.place(undefined, "media"), { x: 0.04, y: 0.44 });
        // The defaults don't overlap, every widget's on a 1920 x 1080 screen at 100 %.
        const rects = DesktopWidgets.kinds.map(k => {
            const p = DesktopWidgets.place({}, k.name);
            const b = DesktopWidgets.box(k.name);
            return { n: k.name, x: p.x * 1920, y: p.y * 1080, w: b.w, h: b.h };
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
        // At 85 % the arrangement zooms toward the middle: a widget against the left and top
        // edges is stored past them, and shows against them again (it stopped 7 % in before).
        const k = 0.85;
        const edge = DesktopWidgets.dropped(0, 0, 300, 150, 1920, 1080, k);
        verify(edge.x < 0 && edge.y < 0);
        compare(DesktopWidgets.shown(edge, 300, 150, 1920, 1080, k), { x: 0, y: 0 });
        // ...and the right and bottom edges.
        const far = DesktopWidgets.dropped(1920 - 300, 1080 - 150, 300, 150, 1920, 1080, k);
        const back = DesktopWidgets.shown(far, 300, 150, 1920, 1080, k);
        fuzzyCompare(back.x, 1620, 0.001);
        fuzzyCompare(back.y, 930, 0.001);
        // Such a place read back from settings isn't thrown away.
        compare(DesktopWidgets.place({ clock: edge }, "clock"), edge);
    }

    function test_screens() {
        const saved = { clock: { x: 0.1, y: 0.1, screen: "DP-2" }, weather: { x: 0.2, y: 0.2 } };
        compare(DesktopWidgets.screenOf(saved, "clock", ["eDP-1", "DP-2"], "eDP-1"), "DP-2");
        // Its screen unplugged, or none saved: the main screen.
        compare(DesktopWidgets.screenOf(saved, "clock", ["eDP-1"], "eDP-1"), "eDP-1");
        compare(DesktopWidgets.screenOf(saved, "weather", ["eDP-1", "DP-2"], "eDP-1"), "eDP-1");
        compare(DesktopWidgets.screenOf(undefined, "clock", ["eDP-1"], "eDP-1"), "eDP-1");
        // The laptop at 0,0 and a 4K screen at 1.5 to its right (2560 x 1440 layout pixels).
        const monitors = [{ name: "eDP-1", x: 0, y: 0, width: 1920, height: 1080, scale: 1, transform: 0 },
                          { name: "DP-2", x: 1920, y: 0, width: 3840, height: 2160, scale: 1.5, transform: 0 }];
        compare(DesktopWidgets.screenAt(monitors, 100, 100), { name: "eDP-1", x: 100, y: 100, w: 1920, h: 1080 });
        compare(DesktopWidgets.screenAt(monitors, 2000, 1200), { name: "DP-2", x: 80, y: 1200, w: 2560, h: 1440 });
        compare(DesktopWidgets.screenAt(monitors, 100, 1200), null);   // below the laptop: no screen
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

    function test_gridLines() {
        // Out from the middle both ways: symmetric.
        compare(DesktopWidgets.gridLines(100, 20), [10, 30, 50, 70, 90]);
        compare(DesktopWidgets.gridLines(100, 0), []);
        const lines = DesktopWidgets.gridLines(1920, 32);
        for (const line of lines)
            verify(lines.some(other => Math.abs(other - (1920 - line)) < 0.001), line);
    }

    function test_gridSnapped() {
        // A medium widget (352 wide) dropped near the middle centers on it.
        compare(DesktopWidgets.gridSnapped(790, 500, 352, 168, 1920, 1080, 32).x, 960 - 176);
        // A small one dropped 5 px off a line: its start moves onto it.
        compare(DesktopWidgets.gridSnapped(965, 500, 168, 168, 1920, 1080, 32).x, 960);
        // A widget and its mirror image land mirrored, at any drop along the side.
        for (const x of [70, 150, 333, 610]) {
            const left = DesktopWidgets.gridSnapped(x, 100, 352, 168, 1920, 1080, 32);
            const right = DesktopWidgets.gridSnapped(1920 - x - 352, 100, 352, 168, 1920, 1080, 32);
            compare(left.x, 1920 - (right.x + 352), x);
        }
        // Never off the screen.
        const edge = DesktopWidgets.gridSnapped(1900, 1070, 168, 168, 1920, 1080, 48);
        verify(edge.x + 168 <= 1920 && edge.y + 168 <= 1080);
    }

    function test_keyStep() {
        compare(DesktopWidgets.keyStep("left", 0, 48), { dx: -48, dy: 0 });
        compare(DesktopWidgets.keyStep("down", 32, 48), { dx: 0, dy: 32 });
        compare(DesktopWidgets.keyStep("tab", 32, 48), null);
    }

    function test_zoom() {
        // At 100 % a place is just its fraction of the screen.
        compare(DesktopWidgets.shown({ x: 0.25, y: 0.5 }, 168, 168, 1920, 1080, 1), { x: 480, y: 540 });
        // Smaller, places move toward the middle by the same factor as the widgets: two widgets
        // side by side at 100 % (a 16 px gap) are still side by side, the gap shrunk with them.
        const k = 0.85;
        const a = DesktopWidgets.shown({ x: 100 / 1920, y: 200 / 1080 }, 168 * k, 168 * k, 1920, 1080, k);
        const b = DesktopWidgets.shown({ x: 284 / 1920, y: 200 / 1080 }, 168 * k, 168 * k, 1920, 1080, k);
        fuzzyCompare(b.x - a.x, 184 * k, 0.001);
        compare(a.y, b.y);
        // The middle stays the middle.
        compare(DesktopWidgets.shown({ x: 0.5, y: 0.5 }, 100, 100, 1920, 1080, 0.85), { x: 960, y: 540 });
        // Larger, kept on the screen.
        compare(DesktopWidgets.shown({ x: 0.95, y: 0 }, 300, 200, 1920, 1080, 1.3).x, 1620);
        // Dropping where it shows gives back the place it came from.
        const place = { x: 0.7, y: 0.3 };
        const at = DesktopWidgets.shown(place, 142, 142, 1920, 1080, k);
        const back = DesktopWidgets.dropped(at.x, at.y, 142, 142, 1920, 1080, k);
        fuzzyCompare(back.x, 0.7, 0.0001);
        fuzzyCompare(back.y, 0.3, 0.0001);
        // A bad zoom counts as 100 %.
        compare(DesktopWidgets.shown({ x: 0.25, y: 0.5 }, 10, 10, 1920, 1080, 0), { x: 480, y: 540 });
    }

    function test_arrange() {
        // A column at the bottom left at 100 %: clock over media, 16 px apart.
        const items = k => [
            { name: "clock", x: 80 / 1920, y: 600 / 1080, w: 352 * k, h: 168 * k },
            { name: "media", x: 80 / 1920, y: 784 / 1080, w: 352 * k, h: 168 * k },
            { name: "timer", x: 1600 / 1920, y: 80 / 1080, w: 168 * k, h: 168 * k }
        ];
        // At 100 % nothing moves.
        compare(DesktopWidgets.arrange(items(1), 1920, 1080, 1, 32).media, { x: 80, y: 784 });
        // At 162 % the column would run off the bottom: it shifts up as one, still 16 px apart
        // (scaled), not piled onto each other.
        const big = DesktopWidgets.arrange(items(1.625), 1920, 1080, 1.625, 32);
        fuzzyCompare(big.media.y - big.clock.y, 184 * 1.625, 0.001);
        verify(big.media.y + 168 * 1.625 <= 1080);
        compare(big.clock.x, big.media.x);
        // The timer, far away, is its own group.
        verify(big.timer.x + 168 * 1.625 <= 1920);
        verify(big.timer.y >= 0);
    }

    function test_nudged() {
        // No grid: by the step, kept on the screen.
        compare(DesktopWidgets.nudged({ x: 0.5, y: 0.5 }, 48, 0, 168, 168, 1920, 1080, 0), { x: (960 + 48) / 1920, y: 0.5 });
        compare(DesktopWidgets.nudged({ x: 0, y: 0 }, -48, -48, 168, 168, 1920, 1080, 0), { x: 0, y: 0 });
        // On the grid: a step of one cell from a line lands on the next line.
        const start = { x: 960 / 1920, y: 540 / 1080 };
        const right = DesktopWidgets.nudged(start, 32, 0, 168, 168, 1920, 1080, 32);
        compare(right.x * 1920, 992);
        const down = DesktopWidgets.nudged(start, 0, 32, 168, 168, 1920, 1080, 32);
        compare(down.y * 1080, 572);
    }

    // A widget turned on next to a row goes at the row's end, not under it (the most compact spot).
    function test_freePlaceCompact() {
        const saved = { clock: { x: 80 / 1920, y: 80 / 1080 }, weather: { x: 448 / 1920, y: 80 / 1080 },
                        battery: { x: 632 / 1920, y: 80 / 1080 },
                        timer: { x: 80 / 1920, y: 80 / 1080 } }; // its own place taken (under the clock)
        const after = DesktopWidgets.freePlace(saved, "timer", ["clock", "weather", "battery"], 1920, 1080);
        compare(after.timer.y, Math.round(80 / 1080 * 10000) / 10000);
        compare(after.timer, { x: Math.round(816 / 1920 * 10000) / 10000, y: Math.round(80 / 1080 * 10000) / 10000 });
    }

    // The calmer side of a picture: busy (a checkerboard) on one third, flat on the other.
    function test_quietSide() {
        const w = 48, h = 27;
        const picture = busySide => {
            const gray = [];
            for (let y = 0; y < h; y++)
                for (let x = 0; x < w; x++)
                    gray.push((busySide === "left" ? x < 16 : x >= 32) ? ((x + y) % 2) * 255 : 128);
            return gray;
        };
        compare(DesktopWidgets.quietSide(picture("left"), w, h), "right");
        compare(DesktopWidgets.quietSide(picture("right"), w, h), "left");
        compare(DesktopWidgets.quietSide(new Array(w * h).fill(100), w, h), "");
        compare(DesktopWidgets.quietSide([1, 2, 3], w, h), "");
    }
}
