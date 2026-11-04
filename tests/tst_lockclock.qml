import QtQuick
import QtTest
import "../quickshell/.config/quickshell/lock/LockClock.js" as LockClock

TestCase {
    name: "LockClock"

    function test_pick() {
        compare(LockClock.pick("analog", LockClock.styles), "analog");
        compare(LockClock.pick("huge", LockClock.styles), "big");
        compare(LockClock.pick(undefined, LockClock.layouts), "top");
        compare(LockClock.pick(125, LockClock.sizes), 125);
        compare(LockClock.pick("125", LockClock.sizes), 75);
    }

    function test_digits() {
        const morning = new Date(2026, 9, 29, 9, 5);
        compare(LockClock.digits(morning, true), { hours: "09", minutes: "05", suffix: "" });
        compare(LockClock.digits(morning, false), { hours: "9", minutes: "05", suffix: "AM" });
        compare(LockClock.digits(new Date(2026, 9, 29, 0, 30), false).hours, "12");
        compare(LockClock.digits(new Date(2026, 9, 29, 12, 0), false), { hours: "12", minutes: "00", suffix: "PM" });
        compare(LockClock.digits(new Date(2026, 9, 29, 23, 59), false), { hours: "11", minutes: "59", suffix: "PM" });
    }

    function test_hands() {
        compare(LockClock.hands(new Date(2026, 9, 29, 0, 0)), { hour: 0, minute: 0 });
        compare(LockClock.hands(new Date(2026, 9, 29, 3, 0)), { hour: 90, minute: 0 });
        compare(LockClock.hands(new Date(2026, 9, 29, 15, 30)), { hour: 105, minute: 180 });
    }

    function test_offset() {
        compare(LockClock.offset(null), { x: 0, y: 0 });
        compare(LockClock.offset({ x: 0.1, y: -0.2 }), { x: 0.1, y: -0.2 });
        compare(LockClock.offset({ x: 3, y: 0 }), { x: 0, y: 0 });
        compare(LockClock.offset({ x: "0.1", y: 0 }), { x: 0, y: 0 });
    }

    function test_clamped() {
        // A 400 x 200 column at (760, 200) on a 1920 x 1080 screen; the field at (790, 800), 340 x 40.
        const rect = { x: 760, y: 200, width: 400, height: 200 };
        const field = { x: 790, y: 800, width: 340, height: 40 };
        compare(LockClock.clamped(rect, 100, 50, 1920, 1080, field, 32, 24), { x: 100, y: 50 });
        // Off the left and top edges: kept at the margin.
        compare(LockClock.clamped(rect, -2000, -500, 1920, 1080, field, 32, 24), { x: -728, y: -168 });
        // Onto the field: stops just above it (800 - 24 - 200 = 576).
        compare(LockClock.clamped(rect, 0, 500, 1920, 1080, field, 32, 24), { x: 0, y: 376 });
        // Beside the field (far left), it may go down to the bottom margin.
        compare(LockClock.clamped(rect, -700, 500, 1920, 1080, field, 32, 24), { x: -700, y: 500 });
        // The login screen's power buttons at the bottom right: kept above them there, not
        // beside them.
        const buttons = { x: 1700, y: 1000, width: 180, height: 48 };
        // Dragged down to the bottom right: stops above the buttons (1000 - 24 - 200 = 776).
        compare(LockClock.clamped(rect, 800, 800, 1920, 1080, [field, buttons], 32, 24), { x: 728, y: 576 });
        // The field dragged near the top: no room above it, so under it (100 + 40 + 24 = 164).
        const high = { x: 790, y: 100, width: 340, height: 40 };
        compare(LockClock.clamped(rect, 0, -150, 1920, 1080, high, 32, 24), { x: 0, y: -36 });
        // At the bottom left, beside them: down to the bottom margin (1080 - 32 - 200 = 848).
        compare(LockClock.clamped(rect, -700, 800, 1920, 1080, [field, buttons], 32, 24), { x: -700, y: 648 });
    }

    function test_places() {
        const old = { lockClockOffset: { x: 0.1, y: 0 }, lockWidgetsOffset: { x: 0.5, y: 0.2 } };
        // Before lockPlaces: the clock's move for the clock and date, the widgets' for the rest.
        compare(LockClock.placeOf(null, "date", old), { x: 0.1, y: 0 });
        compare(LockClock.placeOf(null, "weather", old), { x: 0.5, y: 0.2 });
        // Once set, each part on its own; one never moved stays put.
        compare(LockClock.placeOf({ clock: { x: 0.2, y: 0.1 } }, "clock", old), { x: 0.2, y: 0.1 });
        compare(LockClock.placeOf({ clock: { x: 0.2, y: 0.1 } }, "date", old), { x: 0, y: 0 });
        // The first move keeps the others where the old moves had them.
        const places = LockClock.withPlace(null, "weather", { x: 0.3, y: 0.3 }, old, ["clock", "date", "player", "weather"]);
        compare(places, { clock: { x: 0.1, y: 0 }, date: { x: 0.1, y: 0 }, player: { x: 0.5, y: 0.2 }, weather: { x: 0.3, y: 0.3 } });
        compare(LockClock.withPlace(places, "battery", { x: 0, y: -0.1 }, old, ["clock", "battery"]),
                { clock: { x: 0.1, y: 0 }, battery: { x: 0, y: -0.1 } });
    }

    // A w x h picture as od prints it: `busyLeft` gives the left third a checkerboard (very
    // busy), the rest a flat grey; else the other way round.
    function picture(w, h, busyLeft) {
        const rows = [];
        for (let y = 0; y < h; y++) {
            const row = [];
            for (let x = 0; x < w; x++) {
                const busy = busyLeft ? x < w / 3 : x >= w - w / 3;
                row.push(busy ? ((x + y) % 2 ? 230 : 20) : 120);
            }
            rows.push(" " + row.join("  "));
        }
        return rows.join("\n") + "\n";
    }

    function test_quietSide() {
        compare(LockClock.quietSide(picture(12, 6, true), 12, 6), "right");
        compare(LockClock.quietSide(picture(12, 6, false), 12, 6), "left");
        // Evenly flat, or both sides alike: neither.
        compare(LockClock.quietSide(Array(72).fill(120).join(" "), 12, 6), "");
        // Busy only by a trace: neither.
        const faint = Array(72).fill(120);
        faint[0] = 121;
        compare(LockClock.quietSide(faint.join(" "), 12, 6), "");
        // Not the picture: too short, not numbers, out of range, nothing.
        compare(LockClock.quietSide("1 2 3", 12, 6), "");
        compare(LockClock.quietSide(picture(12, 6, true).replace("230", "x"), 12, 6), "");
        compare(LockClock.quietSide(picture(12, 6, true).replace("230", "300"), 12, 6), "");
        compare(LockClock.quietSide("", 12, 6), "");
    }

    function test_sideOf() {
        compare(LockClock.sideOf(300, 1920), "left");
        compare(LockClock.sideOf(960, 1920), "");
        compare(LockClock.sideOf(1100, 1920), "");
        compare(LockClock.sideOf(1700, 1920), "right");
    }

    function test_mirroredMove() {
        // A 400 px part laid out at 760 (centred) and moved 500 right ends up 500 left of the middle.
        compare(LockClock.mirroredMove(760, 400, 500, 1920), -500);
        // A part in the bottom-left corner (laid out at 115) ends up as far from the right edge.
        const dx = LockClock.mirroredMove(115, 300, 0, 1920);
        compare(115 + dx, 1920 - 115 - 300);
    }
}
