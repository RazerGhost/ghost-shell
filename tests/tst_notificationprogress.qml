import QtQuick
import QtTest
import "../quickshell/.config/quickshell/controlcenter/NotificationProgress.js" as NotificationProgress

TestCase {
    name: "NotificationProgress"

    function test_progress() {
        compare(NotificationProgress.progress({ value: 64 }), 0.64);
        compare(NotificationProgress.progress({ value: 0 }), 0);
        compare(NotificationProgress.progress({ value: 150 }), 1);   // clamped
        compare(NotificationProgress.progress({ value: -5 }), 0);
        compare(NotificationProgress.progress({}), -1);              // no progress
        compare(NotificationProgress.progress({ value: "64" }), -1); // not a number
        compare(NotificationProgress.progress(undefined), -1);
    }
}
