import QtQuick
import QtTest
import "../quickshell/.config/quickshell/bar/Greeting.js" as Greeting

TestCase {
    name: "Greeting"

    function test_greeting() {
        compare(Greeting.greeting(8, "Razer", true), "Good morning, Razer");
        compare(Greeting.greeting(12, "Razer", true), "Good afternoon, Razer");
        compare(Greeting.greeting(18, "Razer", true), "Good evening, Razer");
        // Past midnight it's still the evening, until 5.
        compare(Greeting.greeting(2, "Razer", true), "Good evening, Razer");
        compare(Greeting.greeting(5, "", true), "Good morning");
        compare(Greeting.greeting(15, "Razer", false), "Welcome back, Razer");
        compare(Greeting.greeting(15, "", false), "Welcome back");
    }

    function test_count() {
        compare(Greeting.count(1, "task", "tasks"), "1 task");
        compare(Greeting.count(3, "task", "tasks"), "3 tasks");
    }

    function test_firstName() {
        compare(Greeting.firstName("razerghost:x:1000:1000:Ghosty Example,,,:/home/razerghost:/usr/bin/fish\n"), "Ghosty");
        compare(Greeting.firstName("razerghost:x:1000:1000::/home/razerghost:/usr/bin/fish"), "");
        compare(Greeting.firstName("razerghost:x:1000:1000:Ghosty:/home/razerghost:/bin/sh"), "Ghosty");
        compare(Greeting.firstName(""), "");
    }
}
