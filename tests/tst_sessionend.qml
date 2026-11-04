import QtQuick
import QtTest
import "../quickshell/.config/quickshell/lock/SessionEnd.js" as SessionEnd

TestCase {
    name: "SessionEnd"

    function test_message() {
        compare(SessionEnd.message(3, 2, false), "Closing your apps… 1 of 3");
        // An app answered with a dialog: one more window than there were, never "-1 of 3".
        compare(SessionEnd.message(3, 4, false), "Closing your apps… 0 of 4");
        compare(SessionEnd.message(3, 0, false), "Your apps are closed");
        compare(SessionEnd.message(0, 0, false), "");
        compare(SessionEnd.message(3, 1, true), "This app hasn't closed. It may be asking you something.");
        compare(SessionEnd.message(3, 2, true), "These apps haven't closed. They may be asking you something.");
    }
}
