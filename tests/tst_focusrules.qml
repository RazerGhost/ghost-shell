// Tests for focus mode's rules. Run from the repo root:
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/FocusRules.js" as FocusRules

TestCase {
    name: "FocusRules"

    readonly property var off: ({ on: false, timer: -1, breakTimer: -1 })

    function test_start() {
        compare(FocusRules.start(off, { active: false, runs: 3 }), "run");
        compare(FocusRules.start(off, { active: true, runs: 3 }), "use"); // your own timer runs
        // A break runs: the session replaces it.
        compare(FocusRules.start({ on: false, timer: -1, breakTimer: 3 }, { active: true, runs: 3 }), "run");
        // Already in a session: an old "Focus again" changes nothing.
        compare(FocusRules.start({ on: true, timer: 3, breakTimer: -1 }, { active: true, runs: 3 }), "ignore");
    }

    function test_owns() {
        compare(FocusRules.owns({ on: true, timer: 4, breakTimer: -1 }, 4), true);
        compare(FocusRules.owns({ on: true, timer: 4, breakTimer: -1 }, 5), false); // a timer started over it
        compare(FocusRules.owns({ on: true, timer: -1, breakTimer: -1 }, 4), false); // used one already running
        compare(FocusRules.owns({ on: false, timer: -1, breakTimer: 6 }, 6), true); // its break
    }

    function test_stopCancels() {
        compare(FocusRules.stopCancels({ on: true, timer: 4 }, { active: true, runs: 4 }), true);
        compare(FocusRules.stopCancels({ on: true, timer: 4 }, { active: true, runs: 5 }), false);
        compare(FocusRules.stopCancels({ on: true, timer: -1 }, { active: true, runs: 4 }), false);
        compare(FocusRules.stopCancels({ on: true, timer: 4 }, { active: false, runs: 4 }), false);
    }

    function test_onBreak() {
        compare(FocusRules.onBreak({ breakTimer: 2 }, { active: true, runs: 2 }), true);
        compare(FocusRules.onBreak({ breakTimer: 2 }, { active: false, runs: 2 }), false);
        compare(FocusRules.onBreak({ breakTimer: -1 }, { active: true, runs: 2 }), false);
    }
}
