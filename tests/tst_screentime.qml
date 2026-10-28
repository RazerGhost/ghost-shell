import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/ScreenTime.js" as ScreenTime

TestCase {
    name: "ScreenTime"

    function test_day() {
        compare(ScreenTime.day(new Date(2026, 0, 5, 23, 59)), "2026-01-05");
    }

    function test_add() {
        let data = ScreenTime.add({}, "2026-10-29", "zen", 10);
        data = ScreenTime.add(data, "2026-10-29", "zen", 10);
        data = ScreenTime.add(data, "2026-10-29", "ghostty", 10);
        compare(data, { "2026-10-29": { zen: 20, ghostty: 10 } });
        // Only the newest 30 days stay.
        let month = {};
        for (let d = 1; d <= 31; d++)
            month = ScreenTime.add(month, ScreenTime.day(new Date(2026, 9, d)), "zen", 10);
        compare(Object.keys(month).length, 30);
        verify(!("2026-10-01" in month));
    }

    function test_apps_and_total() {
        const data = { "2026-10-29": { zen: 20, ghostty: 30 } };
        compare(ScreenTime.apps(data, "2026-10-29"), [{ app: "ghostty", seconds: 30 }, { app: "zen", seconds: 20 }]);
        compare(ScreenTime.total(data, "2026-10-29"), 50);
        compare(ScreenTime.apps(data, "2026-10-28"), []);
        compare(ScreenTime.total(data, "2026-10-28"), 0);
    }

    function test_week() {
        const data = { "2026-10-29": { zen: 60 }, "2026-10-23": { zen: 30 }, "2026-10-22": { zen: 99 } };
        const week = ScreenTime.week(data, new Date(2026, 9, 29, 12));
        compare(week.length, 7);
        compare(week[0], { day: "2026-10-23", seconds: 30 });
        compare(week[6], { day: "2026-10-29", seconds: 60 });
        // Across a month's end.
        compare(ScreenTime.week({}, new Date(2026, 10, 2))[0].day, "2026-10-27");
    }

    function test_format() {
        compare(ScreenTime.format(30), "< 1 min");
        compare(ScreenTime.format(12 * 60 + 5), "12 min");
        compare(ScreenTime.format(3 * 3600), "3 h");
        compare(ScreenTime.format(3 * 3600 + 12 * 60), "3 h 12 min");
    }
}
