import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Planner.js" as Planner

TestCase {
    name: "Planner"

    function test_todos() {
        let todos = Planner.add([], "  Buy milk ");
        todos = Planner.add(todos, "Call Sam");
        compare(Planner.add(todos, "   "), todos);
        compare(todos, [{ text: "Buy milk", done: false }, { text: "Call Sam", done: false }]);
        const toggled = Planner.toggle(todos, 0);
        verify(toggled[0].done);
        verify(!todos[0].done); // not changed in place
        compare(Planner.clearDone(toggled), [{ text: "Call Sam", done: false }]);
        compare(Planner.remove(todos, 1), [{ text: "Buy milk", done: false }]);
    }

    function test_valid() {
        compare(Planner.valid([{ text: "a", done: 1 }, { text: "" }, null, { done: true }, { text: "b", done: true }]),
                [{ text: "a", done: false }, { text: "b", done: true }]);
        compare(Planner.valid("nope"), []);
    }

    function test_remaining() {
        compare(Planner.remaining(245000), "4:05");
        compare(Planner.remaining(244100), "4:05"); // rounded up
        compare(Planner.remaining(3723000), "1:02:03");
        compare(Planner.remaining(-5), "0:00");
    }
}
