import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Phone.js" as Phone

TestCase {
    name: "Phone"

    function test_parse() {
        const phones = Phone.parse("a1b2_c3\tPixel 8 Pro\t80\ttrue\n"
                                   + "d4e5\t\t\t\n"           // no name, no battery
                                   + "bad id!\tX\t50\tfalse\n" // not an id: left out
                                   + "f6\tOld\t140\tfalse\n"   // a battery beyond 100: unknown
                                   + "\n");
        compare(phones.length, 3);
        compare(phones[0], { id: "a1b2_c3", name: "Pixel 8 Pro", battery: 80, charging: true });
        compare(phones[1], { id: "d4e5", name: "Phone", battery: null, charging: false });
        compare(phones[2].battery, null);
        compare(Phone.parse(""), []);
    }

    function test_label() {
        compare(Phone.label(null), "Not connected");
        compare(Phone.label({ battery: null, charging: false }), "Connected");
        compare(Phone.label({ battery: 64, charging: false }), "64% battery");
        compare(Phone.label({ battery: 64, charging: true }), "64% battery, charging");
    }
}
